"""
Owner: Leo (backend: submissions, grades, grade-query endpoints).

Submissions module (create / read / update / delete), always for the
logged-in student's own submissions:
  GET    /assignments/{student_id}                 read: assignments + status
  POST   /assignments/{assignment_id}/submit       create: mark as submitted
  PUT    /assignments/submissions/{submission_id}  update: replace the file
  DELETE /assignments/submissions/{submission_id}  delete: withdraw
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.api.deps import get_current_student
from app.database import get_db
from app.models.assignment import Assignment
from app.models.course import Course
from app.models.submission import Submission
from app.services.submission_service import (
    replace_submission_file,
    withdraw_student_submission,
)

router = APIRouter(prefix="/assignments", tags=["assignments"])


@router.get("/{student_id}")
def get_assignments(student_id: int, db: Session = Depends(get_db)):
    results = (
        db.query(Assignment, Submission, Course.course_code)
        .join(
            Submission,
            Assignment.assignment_id == Submission.assignment_id
        )
        .join(
            Course,
            Assignment.course_id == Course.course_id
        )
        .filter(Submission.student_id == student_id)
        .all()
    )

    return [
        {
            "id": assignment.assignment_id,
            "module_code": course_code,
            "title": assignment.title,
            "status": submission.status,
            "due_date": (
                assignment.due_date.date().isoformat()
                if assignment.due_date
                else None
            ),
        }
        for assignment, submission, course_code in results
    ]


@router.post("/{assignment_id}/submit")
def submit_assignment(
    assignment_id: int,
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
    submission = (
        db.query(Submission)
        .filter(
            Submission.assignment_id == assignment_id,
            Submission.student_id == student.student_id,
        )
        .first()
    )

    if submission is None:
        raise HTTPException(
            status_code=404,
            detail="Submission not found for this assignment"
        )

    submission.status = "submitted"
    submission.submitted_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(submission)

    return {
        "status": "submitted",
        "assignment_id": assignment_id
    }


@router.put("/submissions/{submission_id}")
async def update_submission(
    submission_id: int,
    file: UploadFile = File(...),
    student=Depends(get_current_student),
    db: Session = Depends(get_db)
):
    return await replace_submission_file(
        submission_id=submission_id,
        student_id=student.student_id,
        file=file,
        db=db,
    )


@router.delete("/submissions/{submission_id}")
def withdraw_submission(
    submission_id: int,
    student=Depends(get_current_student),
    db: Session = Depends(get_db)
):
    return withdraw_student_submission(
        submission_id=submission_id,
        student_id=student.student_id,
        db=db,
    )
