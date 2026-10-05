"""
Owner: unassigned — flag in the group chat (see docs/folder-ownership.md).

GET /course-materials/{module_code} — see docs/API_CONTRACT.md. Backs US04
and the Course Materials wireframe (Annuschka's screen).
"""
from fastapi import APIRouter

router = APIRouter(prefix="/course-materials", tags=["course-materials"])


@router.get("/{module_code}")
def get_course_materials(module_code: str):
    raise NotImplementedError("TODO: implement per docs/API_CONTRACT.md")
