from .role import Role
from .user import User
from .student import Student
from .lecturer_admin import LecturerAdmin
from .course import Course
from .enrolment import Enrolment
from .assignment import Assignment
from .submission import Submission
from .grade import Grade
from .timetable import Timetable
from .announcement import Announcement
from .course_material import CourseMaterial
from .sync_operation import SyncOperation
from .sync_metadata import SyncMetadata
from .conflict import Conflict

__all__ = [
    "Role", "User", "Student", "LecturerAdmin", "Course", "Enrolment",
    "Assignment", "Submission", "Grade", "Timetable", "Announcement",
    "CourseMaterial", "SyncOperation", "SyncMetadata", "Conflict",
]
