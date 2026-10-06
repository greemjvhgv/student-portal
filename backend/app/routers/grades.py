"""
Owner: Leo (backend: submissions, grades, grade-query endpoints).

GET /grades/{student_id} returns a student's grades.
The module code is resolved through Grade -> Assignment -> Course.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.grade import Grade
from app.models.assignment import Assignment
from app.models.course import Course


router = APIRouter(prefix="/grades", tags=["grades"])


@router.get("/{student_id}")
def get_grades(student_id: int, db: Session = Depends(get_db)):
    """
    Return all grades belonging to the requested student.

    Grade records are joined to Assignment and Course so that the
    course code can be returned as module_code, matching the API contract.
    """

    results = (
        db.query(Grade, Course.course_code)
        .join(
            Assignment,
            Grade.assignment_id == Assignment.assignment_id
        )
        .join(
            Course,
            Assignment.course_id == Course.course_id
        )
        .filter(Grade.student_id == student_id)
        .all()
    )

    return [
        {
            "module_code": course_code,
            "mark": grade.mark,
            "updated_at": (
                grade.updated_at.date().isoformat()
                if grade.updated_at
                else None
            ),
        }
        for grade, course_code in results
    ]
    