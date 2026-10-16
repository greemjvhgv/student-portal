
"""
Owner: Adnan
Submission model for student assignments."""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Submission(Base):
    __tablename__ = "submissions"

    submission_id = Column(Integer, primary_key=True, index=True)

    assignment_id = Column(
        Integer,
        ForeignKey("assignments.assignment_id"),
        nullable=False
    )

    student_id = Column(
        Integer,
        ForeignKey("students.student_id"),
        nullable=False)

    file_path = Column(String, nullable=True)

    status = Column(
        String,
        nullable=False,
        default="not_submitted")

    submitted_at = Column(DateTime(timezone=True), nullable=True)

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False)

    # Access the assignment and student linked to this submission.
    assignment = relationship("Assignment")
    student = relationship("Student")
