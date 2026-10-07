"""
Owner: Leo (backend: additional student portal endpoints).

GET /timetable/{student_id} returns the timetable entries for all
courses in which the requested student is enrolled.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.timetable import Timetable
from app.models.enrolment import Enrolment
from app.models.course import Course


router = APIRouter(prefix="/timetable", tags=["timetable"])


@router.get("/{student_id}")
def get_timetable(student_id: int, db: Session = Depends(get_db)):
    """
    Return timetable entries for the requested student.

    Enrolment links the student to their courses. Each course is then
    joined to its corresponding timetable entries.
    """

    results = (
        db.query(Timetable, Course.course_code)
        .join(
            Enrolment,
            Timetable.course_id == Enrolment.course_id
        )
        .join(
            Course,
            Timetable.course_id == Course.course_id
        )
        .filter(Enrolment.student_id == student_id)
        .all()
    )

    return [
        {
            "module_code": course_code,
            "day": timetable.day_of_week,
            "time": timetable.start_time.strftime("%H:%M"),
            "type": timetable.venue or "Lecture",
        }
        for timetable, course_code in results
    ]

    