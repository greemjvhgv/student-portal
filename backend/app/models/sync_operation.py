"""
Owner: Adnan (D3 Data Design ERD) / used by Ofentse's sync_service.py.
Pending-changes queue — generic/polymorphic, keyed by entity_type +
entity_id so it can log a change against any synced table.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func
from app.database import Base


class SyncOperation(Base):
    __tablename__ = "sync_operations"

    sync_id = Column(Integer, primary_key=True, index=True)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    operation_type = Column(String, nullable=False)
    payload = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    status = Column(String, default="pending")
    attempts = Column(Integer, default=0)
