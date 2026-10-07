"""
Owner: Leo (backend: additional student portal endpoints).

GET /announcements returns all announcements using the response
shape defined in docs/API_CONTRACT.md.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.announcement import Announcement


router = APIRouter(prefix="/announcements", tags=["announcements"])


@router.get("")
def get_announcements(db: Session = Depends(get_db)):
    """
    Return all announcements from the database.

    The database uses 'content' and 'created_at', while the API
    contract exposes these values as 'body' and 'posted_at'.
    """

    announcements = (
        db.query(Announcement)
        .order_by(Announcement.created_at.desc())
        .all()
    )

    return [
        {
            "title": announcement.title,
            "body": announcement.content,
            "posted_at": (
                announcement.created_at.date().isoformat()
                if announcement.created_at
                else None
            ),
        }
        for announcement in announcements
    ]
