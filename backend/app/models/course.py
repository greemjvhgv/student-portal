"""
Owner: Adnan
Course model for student portal
"""
from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class Course(Base):
    __tablename__ = "courses"

    course_id = Column(Integer, primary_key=True, index=True)
    course_code = Column(String, unique=True, nullable=False, index=True)
    course_name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    lecturer_id = Column(Integer, ForeignKey("lecturers_admins.lecturer_id"), nullable=True)

    #allows access to the lecturer that is assigned to this course
    lecturer = relationship("LecturerAdmin")


