
"""
Owner: Adnan
Grade model for student assignment results."""

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Grade(Base):
    __tablename__ = "grades"

    grade_id = Column(Integer, primary_key=True, index=True)

    assignment_id = Column(
        Integer,
        ForeignKey("assignments.assignment_id"),
        nullable=False)

    student_id = Column(
        Integer,
        ForeignKey("students.student_id"),
        nullable=False)

    mark = Column(Float, nullable=False)
    grade_value = Column(String, nullable=True)
    comment = Column(String, nullable=True)

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False)

    # Access the assignment and student associated with this grade.
    assignment = relationship("Assignment")
    student = relationship("Student")
