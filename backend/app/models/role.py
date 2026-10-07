"""
Owner: Adnan (D3 Data Design ERD). Starting point scaffolded from your ERD
— check field names/types against your actual diagram and adjust.
"""
from sqlalchemy import Column, Integer, String
from app.database import Base


class Role(Base):
    __tablename__ = "roles"

    role_id = Column(Integer, primary_key=True, index=True)
    role_name = Column(String, nullable=False, unique=True)
