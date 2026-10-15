"""
Owner: Adnan
Role model for student portal accounts
"""
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.database import Base


class Role(Base):
    __tablename__ = "roles"

    role_id = Column(Integer, primary_key=True, index=True)
    role_name = Column(String, nullable=False, unique=True)

    #role can be assigned to multiple users
    users = relationship("User", back_populates="role")


