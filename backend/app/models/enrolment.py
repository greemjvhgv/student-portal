"""
Owner: Adnan (D3 Data Design ERD). Student<->Course junction table.
"""
from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from app.database import Base


class Enrolment(Base):
    __tablename__ = "enrolments"

    enrolment_id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.student_id"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.course_id"), nullable=False)
    enrolled_at = Column(DateTime(timezone=True), server_default=func.now())
