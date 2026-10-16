"""
Owner: Adnan
lecturer and admin profile model
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.database import Base


class LecturerAdmin(Base):
    __tablename__ = "lecturers_admins"

    lecturer_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False, unique=True)
    first_name = Column(String, nullable=False)
    last_name = Column(String, nullable=False)

    #allow access to the account linked to it
    user = relationship("User")

