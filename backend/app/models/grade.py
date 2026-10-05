"""
Owner: Adnan (D3 Data Design ERD), read by Leo's grades router. module_code
is resolved via Grade -> Assignment -> Course, not stored here directly.
"""
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database import Base


class Grade(Base):
    __tablename__ = "grades"

    grade_id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(Integer, ForeignKey("assignments.assignment_id"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.student_id"), nullable=False)
    mark = Column(Float, nullable=False)
    grade_value = Column(String, nullable=True)
    comment = Column(Text, nullable=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now(), server_default=func.now())
