
"""
Owner:Adnan
Metadata for tracking record synchronisation."""

from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func

from app.database import Base


class SyncMetadata(Base):
    __tablename__ = "sync_metadata"

    metadata_id = Column(Integer, primary_key=True, index=True)

    entity_type = Column(String, nullable=False)
    entity_id = Column(String, nullable=False)

    local_version = Column(
        Integer,
        nullable=False,
        default=0)

    server_version = Column(
        Integer,
        nullable=False,
        default=0)

    last_synced_at = Column(DateTime(timezone=True), nullable=True)

    last_modified_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False)
