"""
Owner: Leo (backend: submissions, grades, grade-query endpoints).

GET /assignments/{student_id} returns assignments for a student.
POST /assignments/{id}/submit updates the student's submission status.
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.database import get_db
from app.models.assignment import Assignment
from app.models.submission import Submission
from app.models.course import Course

from app.api.deps import get_current_student

from app.services.submission_files import (
    save_submission_file,
    delete_submission_file,
)

from app.services.submission_service import (
    replace_submission_file,
    delete_student_submission,
)

router = APIRouter(prefix="/assignments", tags=["assignments"])


@router.get("/{student_id}")
def get_assignments(student_id: int, db: Session = Depends(get_db)):
    """
    Return the assignments associated with the requested student.

    The student's assignment status is stored in Submission, while
    Assignment and Course provide the assignment and module information.
    """

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
    db: Session = Depends(get_db)
):
    submission = (
        db.query(Submission)
        .filter(Submission.assignment_id == assignment_id)
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
    """Update a submission belonging to the authenticated student."""

    return await replace_submission_file(
        submission_id=submission_id,
        student_id=student.student_id,
        file=file,
        db=db,
    )

@router.delete("/submissions/{submission_id}")
def delete_submission(
    submission_id: int,
    student=Depends(get_current_student),
    db: Session = Depends(get_db)
):
    """Delete a submission belonging to the authenticated student."""

    return delete_student_submission(
        submission_id=submission_id,
        student_id=student.student_id,
        db=db,
    )
