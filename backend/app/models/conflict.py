"""
Owner: Adnan (D3 Data Design ERD) / used by Ofentse's sync_service.py.
Records both sides of a sync conflict for auditing — backs the Conflict
Resolution screen (US03 / US06): server's more-recent update wins.
"""
from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func
from app.database import Base


class Conflict(Base):
    __tablename__ = "conflicts"

    conflict_id = Column(Integer, primary_key=True, index=True)
    entity_type = Column(String, nullable=False)
    entity_id = Column(Integer, nullable=False)
    local_version = Column(Integer, nullable=True)
    server_version = Column(Integer, nullable=True)
    local_data = Column(Text, nullable=True)
    server_data = Column(Text, nullable=True)
    resolution_status = Column(String, default="server_wins")
    resolved_at = Column(DateTime(timezone=True), server_default=func.now())
