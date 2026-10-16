"""
Owner:Adnan
Enrolment model linking students and courses
"""
from sqlalchemy import Column, Integer, ForeignKey, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base


class Enrolment(Base):
    __tablename__ = "enrolments"

    enrolment_id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.student_id"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.course_id"), nullable=False)
    enrolled_at = Column(DateTime(timezone=True), server_default=func.now(), nullable = False)

    #access student and course linked to the enrolement
    student = relationship("Student")
    course = relationship("Course")


