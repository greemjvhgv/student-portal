"""
Owner: Ofentse (backend: sync service + conflict resolution).

POST /sync/push and GET /sync/pull/{student_id} — see
docs/API_CONTRACT.md. Delegate the actual conflict decision to
app/services/sync_service.py.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push")
def sync_push():
    raise NotImplementedError("TODO (Ofentse): implement per docs/API_CONTRACT.md")


@router.get("/pull/{student_id}")
def sync_pull(student_id: int):
    raise NotImplementedError("TODO (Ofentse): implement per docs/API_CONTRACT.md")
