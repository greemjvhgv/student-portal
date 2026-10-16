
"""
Owner:Adnan
Model for queued offline synchronisation operations."""

from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func

from app.database import Base


class SyncOperation(Base):
    __tablename__ = "sync_operations"

    sync_id = Column(Integer, primary_key=True, index=True)

    entity_type = Column(String, nullable=False)
    entity_id = Column(String, nullable=False)
    operation_type = Column(String, nullable=False)

    payload = Column(Text, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False)

    status = Column(
        String,
        nullable=False,
        default="pending")

    attempts = Column(
        Integer,
        nullable=False,
        default=0)
