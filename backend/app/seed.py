
"""
Demo seed data for the Student Portal.
Run from the backend directory:
    python -m app.seed

It is safe to run repeatedly: The existing demo records are reused.
"""
from datetime import date, datetime, time, timedelta, timezone

import bcrypt
from sqlalchemy import delete, select

from app.database import Base, SessionLocal, engine
import app.models

from app.models import (
    Role,
    User,
    Student,
    LecturerAdmin,
    Course,
    Enrolment,
    Assignment,
    Submission,
    Grade,
    Timetable,
    Announcement,
    CourseMaterial,)


TEST_PASSWORD ="Test@123"

# South African Standard Time: UTC+2 all year (no daylight saving).
SAST = timezone(timedelta(hours=2))


def due_at(day: date) -> datetime:
    """A deadline of 23:59 South African time on `day`, stored the way the
    server stores every time: in UTC without tzinfo (21:59). Saving 23:59
    directly made the app show deadlines at 01:59 the next day."""
    local = datetime.combine(day, time(23, 59), tzinfo=SAST)
    return local.astimezone(timezone.utc).replace(tzinfo=None)

STUDENTS = [
    ("Annuschka", "Deysel","EDUV4772514"),
    ("Ruan", "van Schalkwyk","EDUV4929929"),
    ("Ofentse","Masetlane", "EDUV4825320"),
    ("Charleen", "Van Deventer", "EDUV4904715"),
    ("Adnan", "Shaikh", "EDUV4968230"),
    ("Leo", "Van Rooi", "EDUV4962498"),
]

COURSES = [
    ("ITMDA3-34", "Project - Mobile & Web Services"),
    ("ITMTA3-33", "Calculus Mathematics"),
    ("ITOPE3-33", "Operating Systems"),
]


def get_or_create(db, model, lookup, defaults=None):
    instance = db.execute(
        select(model).filter_by(**lookup)
    ).scalar_one_or_none()

    if instance is not None:
        return instance

    values = {**lookup, **(defaults or {})}
    instance = model(**values)
    db.add(instance)
    db.flush()
    return instance


def hash_password(password):
    return bcrypt.hashpw(
        password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        today = date.today()
        today_name = today.strftime("%A")
        next_day_name = (
            today + timedelta(days=1)
        ).strftime("%A")

        # 1. Roles
        student_role = get_or_create(
            db, Role, {"role_name": "student"}
        )
        lecturer_role = get_or_create(
            db, Role, {"role_name": "lecturer"}
        )

        # 2. Lecturer account and profile
        lecturer_user = get_or_create(
            db,
            User,
            {"email": "lecturer@test.local"},
            {
                "password_hash": hash_password(TEST_PASSWORD),
                "role_id": lecturer_role.role_id,
            },
        )

        lecturer = get_or_create(
            db,
            LecturerAdmin,
            {"user_id": lecturer_user.user_id},
            {
                "first_name": "Demo",
                "last_name": "Lecturer",
            },
        )

        # 3. Student accounts and profiles
        student_records = []

        for first_name, last_name, student_number in STUDENTS:
            email = f"{student_number.lower()}@test.local"

            user = get_or_create(
                db,
                User,
                {"email": email},
                {
                    "password_hash": hash_password(TEST_PASSWORD),
                    "role_id": student_role.role_id,
                },
            )

            student = get_or_create(
                db,
                Student,
                {"student_number": student_number},
                {
                    "user_id": user.user_id,
                    "first_name": first_name,
                    "last_name": last_name,
                },
            )

            student_records.append(student)

        # 4. Courses
        course_records = {}

        for code, name in COURSES:
            course = get_or_create(
                db,
                Course,
                {"course_code": code},
                {
                    "course_name": name,
                    "lecturer_id": lecturer.lecturer_id,
                },
            )
            course_records[code] = course

        # 5. Enrol all six students in all three courses
        for student in student_records:
            for course in course_records.values():
                get_or_create(
                    db,
                    Enrolment,
                    {
                        "student_id": student.student_id,
                        "course_id": course.course_id,
                    },
                )

        # 6. Timetable
        # Two classes per course today, one tomorrow.
        # This guarantees a populated Today's Timetable.
        # Old slots are removed first, so a seed run on another
        # day replaces the timetable instead of adding to it.
        db.execute(
            delete(Timetable).where(
                Timetable.course_id.in_(
                    [c.course_id for c in course_records.values()]
                )
            )
        )
        timetable_slots = [
            (today_name, time(8, 0), time(9, 0), "Room A101"),
            (today_name, time(11, 0), time(12, 0), "Room B202"),
            (next_day_name, time(10, 0), time(11, 0), "Lab C303"),
        ]

        for course in course_records.values():
            for day, start, end, venue in timetable_slots:
                get_or_create(
                    db,
                    Timetable,
                    {
                        "course_id": course.course_id,
                        "day_of_week": day,
                        "start_time": start,
                    },
                    {
                        "end_time": end,
                        "venue": venue,
                    },
                )

        # 7. Announcements
        announcements = [
            (
                None,
                "Portal maintenance",
                "The student portal will undergo maintenance on Saturday at 10pm.",
                3,
            ),
            (
                course_records["ITMDA3-34"].course_id,
                "New study guide uploaded",
                "The latest study guide is available under course materials.",
                1,
            ),
            (
                course_records["ITMTA3-33"].course_id,
                "Calculus revision session",
                "A revision session has been scheduled for next week.",
                2,
            ),
            (
                course_records["ITOPE3-33"].course_id,
                "Operating Systems resources",
                "Additional learning resources are now available.",
                0,
            ),
        ]

        for course_id, title, content, days_ago in announcements:
            get_or_create(
                db,
                Announcement,
                {"title": title},
                {
                    "course_id": course_id,
                    "content": content,
                    "created_at": datetime.now()
                    - timedelta(days=days_ago),
                },
            )

        # 8. Assignments
        assignment_definitions = [
            (
                "ITMDA3-34",
                "Deliverable 4",
                "Complete and submit Deliverable 4.",
                7,
            ),
            (
                "ITMDA3-34",
                "Deliverable 5",
                "Complete and submit Deliverable 5.",
                14,
            ),
            (
                "ITMTA3-33",
                "Calculus Problem Set",
                "Complete the assigned calculus exercises.",
                10,
            ),
            (
                "ITOPE3-33",
                "Operating Systems Research",
                "Research operating system scheduling.",
                12,
            ),
        ]

        assignment_records = {}

        for code, title, description, days_until_due in assignment_definitions:
            course = course_records[code]
            due_date = due_at(today + timedelta(days=days_until_due))

            assignment = get_or_create(
                db,
                Assignment,
                {
                    "course_id": course.course_id,
                    "title": title,
                },
                {
                    "description": description,
                    "due_date": due_date,
                },
            )

            # Keep demo deadlines in the future on reruns, and correct
            # deadlines saved by older seeds as 23:59 UTC (shown as 01:59).
            now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
            if (
                assignment.due_date is None
                or assignment.due_date < now_utc
                or assignment.due_date.time() == time(23, 59)
            ):
                assignment.due_date = due_date

            assignment_records[(code, title)] = assignment

        # 9. Submissions: every student has a pending submission
        for student in student_records:
            for assignment in assignment_records.values():
                get_or_create(
                    db,
                    Submission,
                    {
                        "student_id": student.student_id,
                        "assignment_id": assignment.assignment_id,
                    },
                    {"status": "not_submitted"},
                )

        # 10. Grades: 84%, 72%, and no OS grade
        grade_definitions = [
            ("ITMDA3-34", "Deliverable 4", 84.0),
            ("ITMTA3-33", "Calculus Problem Set", 72.0),
        ]

        for student in student_records:
            for code, title, mark in grade_definitions:
                assignment = assignment_records[(code, title)]

                get_or_create(
                    db,
                    Grade,
                    {
                        "student_id": student.student_id,
                        "assignment_id": assignment.assignment_id,
                    },
                    {
                        "mark": mark,
                        "grade_value": f"{int(mark)}%",
                        "comment": "Demo assessment grade",
                    },
                )

        # 11. Course materials
        materials = [
            (
                "ITMDA3-34",
                "Week 6 - Lecture Slides.pdf",
                "/demo/materials/itmda/week6-slides.pdf",
            ),
            (
                "ITMDA3-34",
                "Study Guide - Databases.pdf",
                "/demo/materials/itmda/database-guide.pdf",
            ),
            (
                "ITMTA3-33",
                "Week 6 - Lecture Slides.pdf",
                "/demo/materials/itmta/week6-slides.pdf",
            ),
            (
                "ITMTA3-33",
                "Week 6 - Course Slides.pdf",
                "/demo/materials/itmta/week6-course.pdf",
            ),
            (
                "ITOPE3-33",
                "Week 6 - Lecture Slides.pdf",
                "/demo/materials/itope/week6-slides.pdf",
            ),
        ]

        for code, title, file_url in materials:
            get_or_create(
                db,
                CourseMaterial,
                {
                    "course_id": course_records[code].course_id,
                    "title": title,
                },
                {"file_url": file_url},
            )

        # SyncOperation, SyncMetadata and Conflict are
        # deliberately not populated.

        db.commit()

        print("Seed completed successfully!")
        print(f"Students: {len(student_records)}")
        print(f"Courses: {len(course_records)}")
        print("Lecturer: lecturer@test.local")
        print(f"Today's timetable day: {today_name}")
        print(f"Demo password: {TEST_PASSWORD}")

    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
