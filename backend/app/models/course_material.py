"""
Owner: Adnan (extend into the ERD if the group wants it formalized there —
this wasn't in the original D3 diagram, added to back the Course Materials
screen/endpoint).
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from app.database import Base


class CourseMaterial(Base):
    __tablename__ = "course_materials"

    material_id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.course_id"), nullable=False)
    title = Column(String, nullable=False)
    file_url = Column(String, nullable=False)
