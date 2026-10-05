"""
Owner: unassigned — flag in the group chat (see docs/folder-ownership.md).

GET /announcements — see docs/API_CONTRACT.md for the exact response
shape. Backs US02/US09 and the Dashboard wireframe's "Announcements" card
(Charleen's screen).
"""
from fastapi import APIRouter

router = APIRouter(prefix="/announcements", tags=["announcements"])


@router.get("")
def get_announcements():
    raise NotImplementedError("TODO: implement per docs/API_CONTRACT.md")
