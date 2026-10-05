"""
Owner: unassigned — flag in the group chat (see docs/folder-ownership.md).

GET /timetable/{student_id} — see docs/API_CONTRACT.md for the exact
response shape. Backs US01 and the Dashboard wireframe's "Today's
Timetable" card (Charleen's screen).
"""
from fastapi import APIRouter

router = APIRouter(prefix="/timetable", tags=["timetable"])


@router.get("/{student_id}")
def get_timetable(student_id: int):
    raise NotImplementedError("TODO: implement per docs/API_CONTRACT.md")
