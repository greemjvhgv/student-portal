"""
Owner: Adnan (D3 Data Design ERD). Starting point — check against your
actual diagram and adjust.
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from app.database import Base


class Student(Base):
    __tablename__ = "students"

    student_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, unique=True)
    student_number = Column(String, unique=True, index=True, nullable=False)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
