"""
Owner: Leo (backend: submissions, grades, grade-query endpoints).

GET /assignments/{student_id} and POST /assignments/{id}/submit — see
docs/API_CONTRACT.md for the exact shapes. Per Adnan's ERD, a student's
per-assignment status lives in Submission, not Assignment itself.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/assignments", tags=["assignments"])


@router.get("/{student_id}")
def get_assignments(student_id: int):
    raise NotImplementedError("TODO (Leo): implement per docs/API_CONTRACT.md")


@router.post("/{assignment_id}/submit")
def submit_assignment(assignment_id: int):
    raise NotImplementedError("TODO (Leo): implement per docs/API_CONTRACT.md")
