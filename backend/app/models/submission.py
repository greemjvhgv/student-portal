"""
Owner: Adnan (D3 Data Design ERD), read/written by Leo's routers. Tracks
one student's submission state for one Assignment (status: not_submitted /
queued / submitted — US05).
"""
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class Submission(Base):
    __tablename__ = "submissions"

    submission_id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(Integer, ForeignKey("assignments.assignment_id"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.student_id"), nullable=False)
    file_path = Column(String, nullable=True)
    status = Column(String, default="not_submitted")
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
