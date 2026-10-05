"""
Owner: Adnan (D3 Data Design ERD). Starting point — check against your
actual diagram and adjust. module_code/module_name in API responses map
to course_code/course_name here.
"""
from sqlalchemy import Column, Integer, String, Text, ForeignKey
from app.database import Base


class Course(Base):
    __tablename__ = "courses"

    course_id = Column(Integer, primary_key=True, index=True)
    course_code = Column(String, unique=True, nullable=False, index=True)
    course_name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    lecturer_id = Column(Integer, ForeignKey("lecturers_admins.lecturer_id"), nullable=True)
