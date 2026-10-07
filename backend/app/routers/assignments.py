"""
Owner: Leo (backend: submissions, grades, grade-query endpoints).

GET /assignments/{student_id} returns assignments for a student.
POST /assignments/{id}/submit updates the student's submission status.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from app.database import get_db
from app.models.assignment import Assignment
from app.models.submission import Submission
from app.models.course import Course


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

    