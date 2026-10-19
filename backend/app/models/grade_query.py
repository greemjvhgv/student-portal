
"""
Grade Query database model.

Proposed by Leo for review with Adnan.
Stores student requests to review assignment grades.
"""

from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

from app.database import Base


class GradeQuery(Base):
    __tablename__ = "grade_queries"

    query_id = Column(Integer, primary_key=True, index=True)

    student_id = Column(
        Integer,
        ForeignKey("students.student_id"),
        nullable=False,
    )

    grade_id = Column(
        Integer,
        ForeignKey("grades.grade_id"),
        nullable=False,
    )

    reason = Column(String(1000), nullable=False)

    status = Column(
        String,
        nullable=False,
        default="pending",
    )

    student = relationship("Student")
    grade = relationship("Grade")
