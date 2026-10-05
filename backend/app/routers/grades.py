"""
Owner: Leo (backend: submissions, grades, grade-query endpoints).

GET /grades/{student_id} — see docs/API_CONTRACT.md for the exact response
shape. module_code needs resolving via Grade -> Assignment -> Course
(Adnan's models).
"""
from fastapi import APIRouter

router = APIRouter(prefix="/grades", tags=["grades"])


@router.get("/{student_id}")
def get_grades(student_id: int):
    raise NotImplementedError("TODO (Leo): implement per docs/API_CONTRACT.md")
