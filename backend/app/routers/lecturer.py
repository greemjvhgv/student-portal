"""
Owner: Annuschka (integration). Lecturer side of the prototype (US08–US10).

D3 describes lecturers updating grades, announcements and the timetable
through a web portal. In this prototype FastAPI's /docs page is that
portal:
  1. POST /lecturer/login with the lecturer's email and password
  2. click "Authorize" at the top of /docs and paste the token
  3. use the endpoints below.
"""
from datetime import datetime, time, timedelta, timezone
from typing import Literal

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import verify_password
from app.database import get_db
from app.models import (
    Announcement,
    Assignment,
    Course,
    Grade,
    LecturerAdmin,
    Student,
    Submission,
    Timetable,
    User,
)

router = APIRouter(prefix="/lecturer", tags=["lecturer"])

_bearer = HTTPBearer(auto_error=False)
_SUBJECT_PREFIX = "lecturer:"


# ----------------------------------------------------------------- Login

class LecturerLoginRequest(BaseModel):
    email: str
    password: str


class LecturerLoginResponse(BaseModel):
    token: str
    lecturer_id: int
    full_name: str


def _create_lecturer_token(lecturer_id: int) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": f"{_SUBJECT_PREFIX}{lecturer_id}",
        "role": "lecturer",
        "iat": now,
        "exp": now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def get_current_lecturer(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> LecturerAdmin:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Lecturer login required",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM],
        )
        subject = str(payload.get("sub", ""))
        if payload.get("role") != "lecturer" or not subject.startswith(_SUBJECT_PREFIX):
            raise unauthorized
        lecturer_id = int(subject[len(_SUBJECT_PREFIX):])
    except (jwt.PyJWTError, ValueError):
        raise unauthorized
    lecturer = db.get(LecturerAdmin, lecturer_id)
    if lecturer is None:
        raise unauthorized
    return lecturer


@router.post("/login", response_model=LecturerLoginResponse)
def lecturer_login(body: LecturerLoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email.strip().lower()).first()
    lecturer = (
        db.query(LecturerAdmin).filter(LecturerAdmin.user_id == user.user_id).first()
        if user
        else None
    )
    password_ok = verify_password(body.password, user.password_hash) if user else False
    if not (user and lecturer and password_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    user.last_login = datetime.now(timezone.utc)
    db.commit()
    return LecturerLoginResponse(
        token=_create_lecturer_token(lecturer.lecturer_id),
        lecturer_id=lecturer.lecturer_id,
        full_name=f"{lecturer.first_name} {lecturer.last_name}",
    )


def _check_own_course(course: Course | None, lecturer: LecturerAdmin) -> None:
    if course is None:
        raise HTTPException(status_code=404, detail="Course not found")
    if course.lecturer_id != lecturer.lecturer_id:
        raise HTTPException(status_code=403, detail="Not your course")


def _iso(value: datetime | None) -> str | None:
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat()


# ---------------------------------------------------------- Grades (US08)

class GradeUpdate(BaseModel):
    mark: float | None = Field(default=None, ge=0, le=100)
    grade_value: str | None = None
    comment: str | None = None


@router.get("/grades")
def list_grades(
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):

    rows = (
        db.query(Grade, Student.student_number, Assignment.title, Course.course_code)
        .join(Student, Grade.student_id == Student.student_id)
        .join(Assignment, Grade.assignment_id == Assignment.assignment_id)
        .join(Course, Assignment.course_id == Course.course_id)
        .filter(Course.lecturer_id == lecturer.lecturer_id)
        .order_by(Grade.grade_id)
        .all()
    )
    return [
        {
            "grade_id": grade.grade_id,
            "student_number": student_number,
            "module_code": course_code,
            "assignment": title,
            "mark": grade.mark,
            "updated_at": _iso(grade.updated_at),
        }
        for grade, student_number, title, course_code in rows
    ]


@router.put("/grades/{grade_id}")
def update_grade(
    grade_id: int,
    body: GradeUpdate,
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    grade = db.get(Grade, grade_id)
    if grade is None:
        raise HTTPException(status_code=404, detail="Grade not found")
    _check_own_course(grade.assignment.course, lecturer)
    changes = body.model_dump(exclude_unset=True)
    if not changes:
        raise HTTPException(status_code=422, detail="Nothing to update")
    for field, value in changes.items():
        setattr(grade, field, value)
    grade.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(grade)
    return {
        "grade_id": grade.grade_id,
        "mark": grade.mark,
        "grade_value": grade.grade_value,
        "comment": grade.comment,
        "updated_at": _iso(grade.updated_at),
    }


# ------------------------------------------------- Submissions (conflicts)

class SubmissionUpdate(BaseModel):
    status: Literal["not_submitted", "submitted"]


@router.get("/submissions")
def list_submissions(
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    rows = (
        db.query(Submission, Student.student_number, Assignment.title, Course.course_code)
        .join(Student, Submission.student_id == Student.student_id)
        .join(Assignment, Submission.assignment_id == Assignment.assignment_id)
        .join(Course, Assignment.course_id == Course.course_id)
        .filter(Course.lecturer_id == lecturer.lecturer_id)
        .order_by(Submission.submission_id)
        .all()
    )
    return [
        {
            "submission_id": submission.submission_id,
            "assignment_id": submission.assignment_id,
            "student_number": student_number,
            "module_code": course_code,
            "assignment": title,
            "status": submission.status,
            "updated_at": _iso(submission.updated_at),
        }
        for submission, student_number, title, course_code in rows
    ]


@router.put("/submissions/{submission_id}")
def update_submission(
    submission_id: int,
    body: SubmissionUpdate,
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    submission = db.get(Submission, submission_id)
    if submission is None:
        raise HTTPException(status_code=404, detail="Submission not found")
    _check_own_course(submission.assignment.course, lecturer)
    submission.status = body.status
    submission.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(submission)
    return {
        "submission_id": submission.submission_id,
        "status": submission.status,
        "updated_at": _iso(submission.updated_at),
    }


# ---------------------------------------------------- Announcements (US09)

class AnnouncementCreate(BaseModel):
    title: str = Field(min_length=1)
    content: str = Field(min_length=1)
    course_id: int | None = None


class AnnouncementUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1)
    content: str | None = Field(default=None, min_length=1)


def _announcement_json(item: Announcement) -> dict:
    return {
        "announcement_id": item.announcement_id,
        "course_id": item.course_id,
        "title": item.title,
        "content": item.content,
        "created_at": _iso(item.created_at),
        "updated_at": _iso(item.updated_at),
    }


def _get_own_announcement(
    announcement_id: int, lecturer: LecturerAdmin, db: Session
) -> Announcement:
    item = db.get(Announcement, announcement_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Announcement not found")
    if item.course_id is not None:
        _check_own_course(item.course, lecturer)
    return item


@router.post("/announcements", status_code=status.HTTP_201_CREATED)
def publish_announcement(
    body: AnnouncementCreate,
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    if body.course_id is not None:
        _check_own_course(db.get(Course, body.course_id), lecturer)
    item = Announcement(title=body.title, content=body.content, course_id=body.course_id)
    db.add(item)
    db.commit()
    db.refresh(item)
    return _announcement_json(item)


@router.put("/announcements/{announcement_id}")
def edit_announcement(
    announcement_id: int,
    body: AnnouncementUpdate,
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    item = _get_own_announcement(announcement_id, lecturer, db)
    changes = body.model_dump(exclude_unset=True)
    if not changes:
        raise HTTPException(status_code=422, detail="Nothing to update")
    for field, value in changes.items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return _announcement_json(item)


@router.delete("/announcements/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_announcement(
    announcement_id: int,
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    item = _get_own_announcement(announcement_id, lecturer, db)
    db.delete(item)
    db.commit()


# -------------------------------------------------------- Timetable (US10)

class TimetableUpdate(BaseModel):
    day_of_week: str | None = None
    start_time: time | None = None
    end_time: time | None = None
    venue: str | None = None


@router.put("/timetable/{timetable_id}")
def update_timetable(
    timetable_id: int,
    body: TimetableUpdate,
    lecturer: LecturerAdmin = Depends(get_current_lecturer),
    db: Session = Depends(get_db),
):
    entry = db.get(Timetable, timetable_id)
    if entry is None:
        raise HTTPException(status_code=404, detail="Timetable entry not found")
    _check_own_course(entry.course, lecturer)
    changes = body.model_dump(exclude_unset=True)
    if not changes:
        raise HTTPException(status_code=422, detail="Nothing to update")
    for field, value in changes.items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return {
        "timetable_id": entry.timetable_id,
        "course_id": entry.course_id,
        "day_of_week": entry.day_of_week,
        "start_time": entry.start_time.strftime("%H:%M"),
        "end_time": entry.end_time.strftime("%H:%M") if entry.end_time else None,
        "venue": entry.venue,
    }
