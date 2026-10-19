
"""
Owner: Adnan
Announcement model for the student portal."""

from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base


class Announcement(Base):
    __tablename__ = "announcements"

    announcement_id = Column(
        Integer,
        primary_key=True,
        index=True)

    course_id = Column(
        Integer,
        ForeignKey("courses.course_id"),
        nullable=True)

    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False)

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False)

    # Access the course associated with this announcement, if any.
    course = relationship("Course")
