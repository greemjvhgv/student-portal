"""
Owner: Adnan (D3 Data Design ERD) / used by Ofentse's sync_service.py.
Tracks local_version vs server_version + timestamps per record — backs the
timestamp-based conflict rule (FR12 / US03 / US06).
"""
from sqlalchemy import Column, Integer, String, DateTime
from app.database import Base


class SyncMetadata(Base):
    __tablename__ = "sync_metadata"

    metadata_id = Column(Integer, primary_key=True, index=True)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    local_version = Column(Integer, default=0)
    server_version = Column(Integer, default=0)
    last_synced_at = Column(DateTime(timezone=True), nullable=True)
    last_modified_at = Column(DateTime(timezone=True), nullable=True)
