"""
Owner: Leo (backend: additional student portal endpoints).

GET /course-materials/{module_code} returns course materials for the
requested module using the response shape in docs/API_CONTRACT.md.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.course_material import CourseMaterial
from app.models.course import Course


router = APIRouter(prefix="/course-materials", tags=["course-materials"])


@router.get("/{module_code}")
def get_course_materials(module_code: str, db: Session = Depends(get_db)):
    materials = (
        db.query(CourseMaterial)
        .join(Course, CourseMaterial.course_id == Course.course_id)
        .filter(Course.course_code == module_code)
        .all()
    )

    return [
        {
            "title": material.title,
            "file_url": material.file_url,
        }
        for material in materials
    ]
