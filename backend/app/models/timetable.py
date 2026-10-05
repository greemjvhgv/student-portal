"""
Owner: Adnan (D3 Data Design ERD). Backs GET /timetable/{student_id}
(joined through Enrolment -> Course).
"""
from sqlalchemy import Column, Integer, String, Time, ForeignKey
from app.database import Base


class Timetable(Base):
    __tablename__ = "timetables"

    timetable_id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.course_id"), nullable=False)
    day_of_week = Column(String, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=True)
    venue = Column(String, nullable=True)
