"""
Owner: Adnan (D3 Data Design ERD). Starting point — check against your
actual diagram and adjust.
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from app.database import Base


class LecturerAdmin(Base):
    __tablename__ = "lecturers_admins"

    lecturer_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, unique=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)
