
"""
Owner:Adnan
Model for tracking offline synchronisation conflicts."""

from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func

from app.database import Base


class Conflict(Base):
    __tablename__ = "conflicts"

    conflict_id = Column(Integer, primary_key=True, index=True)

    entity_type = Column(String, nullable=False)
    entity_id = Column(String, nullable=False)

    local_version = Column(Integer, nullable=True)
    server_version = Column(Integer, nullable=True)

    local_data = Column(Text, nullable=True)
    server_data = Column(Text, nullable=True)

    resolution_status = Column(
        String,
        nullable=False,
        default="server_wins")

    resolved_at = Column(DateTime(timezone=True), nullable=True)
