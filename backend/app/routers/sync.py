"""
Owner: Ofentse (backend: sync service + conflict resolution).

POST /sync/push and GET /sync/pull/{student_id}.
"""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.sync_service import apply_push, pull_changes_since

router = APIRouter(prefix="/sync", tags=["sync"])


class SyncPushItem(BaseModel):
    table: str
    id: int
    status: str
    client_updated_at: datetime


@router.post("/push")
def sync_push(
    changes: list[SyncPushItem],
    db: Session = Depends(get_db),
):
    conflicts = []

    try:
        for change in changes:
            conflict = apply_push(
                db=db,
                table_name=change.table,
                record_id=change.id,
                fields={"status": change.status},
                client_updated_at=change.client_updated_at,
            )

            if conflict is not None:
                conflicts.append(conflict)

        db.commit()

        return {
            "status": "synced",
            "conflicts": conflicts,
        }

    except ValueError as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail=str(exc),
        ) from exc

    except Exception:
        db.rollback()
        raise


@router.get("/pull/{student_id}")
def sync_pull(
    student_id: int,
    db: Session = Depends(get_db),
):
    try:
        return pull_changes_since(db, student_id)

    except ValueError as exc:
        raise HTTPException(
            status_code=404,
            detail=str(exc),
        ) from exc