
"""
Owner:Adnan
Course material model for the student portal."""

from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class CourseMaterial(Base):
    __tablename__ = "course_materials"

    material_id = Column(Integer, primary_key=True, index=True)

    course_id = Column(
        Integer,
        ForeignKey("courses.course_id"),
        nullable=False)

    title = Column(String, nullable=False)
    file_url = Column(String, nullable=False)

    # Access the course associated with this learning material.
    course = relationship("Course")
