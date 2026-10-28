"""
Owner: Ofentse (backend: sync service + conflict resolution).

Handles offline assignment-status updates, operation logging,
server-wins conflict resolution, and student sync pulls.
"""

import json
from datetime import datetime, timezone

from sqlalchemy import select

from app.models.assignment import Assignment
from app.models.announcement import Announcement
from app.models.conflict import Conflict
from app.models.course import Course
from app.models.enrolment import Enrolment
from app.models.grade import Grade
from app.models.grade_query import GradeQuery
from app.models.submission import Submission
from app.models.sync_metadata import SyncMetadata
from app.models.sync_operation import SyncOperation
from app.models.timetable import Timetable


def _as_utc(value):
    if value is None:
        return None

    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)

    return value.astimezone(timezone.utc)


def _json(data):
    return json.dumps(data, default=str)


def apply_push(
    db,
    student_id: int,
    table_name: str,
    record_id: int,
    fields: dict,
    client_updated_at,
):

    if not isinstance(fields, dict):
        raise ValueError("The change fields must be an object.")

    if client_updated_at is None:
        raise ValueError("client_updated_at is required.")

    fields = {key: value for key, value in fields.items() if value is not None}

    if table_name == "grade_queries":
        return _apply_grade_query(db, student_id, record_id, fields, client_updated_at)

    if table_name != "assignments":
        raise ValueError(f"Unsupported table: {table_name}.")

    status = fields.get("status")

    if status not in {"submitted", "not_submitted"}:
        raise ValueError("Unsupported assignment status.")

    assignment = (
        db.query(Assignment)
        .filter(Assignment.assignment_id == record_id)
        .first()
    )

    if assignment is None:
        raise ValueError("Assignment not found.")

    submission = (
        db.query(Submission)
        .filter(
            Submission.assignment_id == record_id,
            Submission.student_id == student_id,
        )
        .first()
    )

    if submission is None:
        raise ValueError("No submission record for this student and assignment.")

    client_time = _as_utc(client_updated_at)
    server_time = _as_utc(submission.updated_at)

    if (
        status == "submitted"
        and submission.status == "submitted"
        and _as_utc(submission.submitted_at) == client_time
    ):
        return None

    entity_type = "submissions"
    entity_id = str(submission.submission_id)

    metadata = (
        db.query(SyncMetadata)
        .filter(
            SyncMetadata.entity_type == entity_type,
            SyncMetadata.entity_id == entity_id,
        )
        .first()
    )

    operation = SyncOperation(
        entity_type=entity_type,
        entity_id=entity_id,
        operation_type="push",
        payload=_json({
            "table": table_name,
            "id": record_id,
            "student_id": student_id,
            **fields,
            "client_updated_at": client_updated_at,
        }),
        status="pending",
        attempts=1,
    )
    db.add(operation)

    if server_time is not None and server_time > client_time:
        db.add(Conflict(
            entity_type=entity_type,
            entity_id=entity_id,
            local_version=metadata.local_version if metadata else None,
            server_version=metadata.server_version if metadata else None,
            local_data=_json({**fields, "client_updated_at": client_updated_at}),
            server_data=_json({
                "assignment_id": assignment.assignment_id,
                "submission_id": submission.submission_id,
                "status": submission.status,
                "updated_at": server_time,
            }),
            resolution_status="server_wins",
            resolved_at=datetime.now(timezone.utc),
        ))

        operation.status = "conflict"

        return {
            "table": table_name,
            "id": record_id,
            "resolution": "server_wins",
            "server_status": submission.status,
            "server_updated_at": server_time.isoformat(),
        }

    submission.status = status

    now = datetime.now(timezone.utc)

    if status == "submitted":
        submission.submitted_at = client_time

    if metadata is None:
        metadata = SyncMetadata(
            entity_type=entity_type,
            entity_id=entity_id,
            local_version=1,
            server_version=1,
        )
        db.add(metadata)
    else:
        metadata.local_version = (metadata.local_version or 0) + 1
        metadata.server_version = (metadata.server_version or 0) + 1

    metadata.last_modified_at = now
    metadata.last_synced_at = now

    operation.status = "applied"

    return None


def _apply_grade_query(db, student_id: int, grade_id: int, fields: dict, client_updated_at):

    reason = (fields.get("reason") or "").strip()

    if len(reason) < 10:
        raise ValueError("A grade query reason needs at least 10 characters.")

    if len(reason) > 1000:
        raise ValueError("A grade query reason can be at most 1000 characters.")

    grade = (
        db.query(Grade)
        .filter(Grade.grade_id == grade_id, Grade.student_id == student_id)
        .first()
    )

    if grade is None:
        raise ValueError("Grade not found for this student.")

    duplicate = (
        db.query(GradeQuery)
        .filter(
            GradeQuery.student_id == student_id,
            GradeQuery.grade_id == grade_id,
            GradeQuery.reason == reason,
            GradeQuery.status == "pending",
        )
        .first()
    )

    if duplicate is not None:
        return None

    client_time = _as_utc(client_updated_at)
    server_time = _as_utc(grade.updated_at)
    entity_id = str(grade_id)

    operation = SyncOperation(
        entity_type="grade_queries",
        entity_id=entity_id,
        operation_type="push",
        payload=_json({
            "table": "grade_queries",
            "grade_id": grade_id,
            "student_id": student_id,
            "reason": reason,
            "client_updated_at": client_updated_at,
        }),
        status="pending",
        attempts=1,
    )
    db.add(operation)

    if server_time is not None and server_time > client_time:
        db.add(Conflict(
            entity_type="grades",
            entity_id=entity_id,
            local_data=_json({"reason": reason, "client_updated_at": client_updated_at}),
            server_data=_json({
                "grade_id": grade_id,
                "mark": grade.mark,
                "updated_at": server_time,
            }),
            resolution_status="server_wins",
            resolved_at=datetime.now(timezone.utc),
        ))

        operation.status = "conflict"

        return {
            "table": "grade_queries",
            "id": grade_id,
            "resolution": "server_wins",
            "server_status": f"mark {grade.mark:g}",
            "server_updated_at": server_time.isoformat(),
        }

    db.add(GradeQuery(
        student_id=student_id,
        grade_id=grade_id,
        reason=reason,
        status="pending",
    ))

    operation.status = "applied"

    return None


def pull_changes_since(db, student_id: int):

    student_exists = (
        db.query(Enrolment)
        .filter(Enrolment.student_id == student_id)
        .first()
    )

    if student_exists is None:
        from app.models.student import Student

        if db.query(Student).filter(
            Student.student_id == student_id
        ).first() is None:
            raise ValueError("Student not found.")

    assignment_rows = (
        db.query(Assignment, Submission, Course.course_code)
        .join(
            Submission,
            Assignment.assignment_id == Submission.assignment_id,
        )
        .join(Course, Assignment.course_id == Course.course_id)
        .filter(Submission.student_id == student_id)
        .all()
    )

    assignments = [
        {
            "id": assignment.assignment_id,
            "module_code": course_code,
            "title": assignment.title,
            "status": submission.status,
            "due_date": (
                _as_utc(assignment.due_date).isoformat()
                if assignment.due_date
                else None
            ),
            "submission_id": submission.submission_id,
        }
        for assignment, submission, course_code in assignment_rows
    ]

    grade_rows = (
        db.query(Grade, Course.course_code, Course.course_name, Assignment.title)
        .join(
            Assignment,
            Grade.assignment_id == Assignment.assignment_id,
        )
        .join(Course, Assignment.course_id == Course.course_id)
        .filter(Grade.student_id == student_id)
        .order_by(Course.course_code, Grade.grade_id)
        .all()
    )

    grades = [
        {
            "id": grade.grade_id,
            "module_code": course_code,
            "module_name": f"{course_name} – {title}",
            "mark": grade.mark,
            "updated_at": (
                grade.updated_at.date().isoformat()
                if grade.updated_at
                else None
            ),
        }
        for grade, course_code, course_name, title in grade_rows
    ]

    graded_codes = {course_code for _, course_code, _, _ in grade_rows}
    enrolled_courses = (
        db.query(Course)
        .join(Enrolment, Enrolment.course_id == Course.course_id)
        .filter(Enrolment.student_id == student_id)
        .order_by(Course.course_code)
        .all()
    )
    grades += [
        {
            "module_code": course.course_code,
            "module_name": course.course_name,
            "mark": None,
            "updated_at": None,
        }
        for course in enrolled_courses
        if course.course_code not in graded_codes
    ]

    timetable_rows = (
        db.query(Timetable, Course.course_code)
        .join(Course, Timetable.course_id == Course.course_id)
        .join(Enrolment, Enrolment.course_id == Course.course_id)
        .filter(Enrolment.student_id == student_id)
        .all()
    )

    timetable = [
        {
            "module_code": course_code,
            "day": item.day_of_week,
            "time": item.start_time.strftime("%H:%M"),
            "type": "Lecture",
            "venue": item.venue,
        }
        for item, course_code in timetable_rows
    ]

    enrolled_course_ids = select(Enrolment.course_id).where(Enrolment.student_id == student_id)

    announcement_rows = (
        db.query(Announcement)
        .filter(
            (Announcement.course_id.is_(None))
            | (Announcement.course_id.in_(enrolled_course_ids))
        )
        .all()
    )

    announcements = [
        {
            "title": item.title,
            "body": item.content,
            "posted_at": (
                item.created_at.date().isoformat()
                if item.created_at
                else None
            ),
        }
        for item in announcement_rows
    ]

    query_rows = (
        db.query(GradeQuery, Course.course_code)
        .join(Grade, GradeQuery.grade_id == Grade.grade_id)
        .join(Assignment, Grade.assignment_id == Assignment.assignment_id)
        .join(Course, Assignment.course_id == Course.course_id)
        .filter(GradeQuery.student_id == student_id)
        .order_by(GradeQuery.query_id.desc())
        .all()
    )

    grade_queries = [
        {
            "query_id": query.query_id,
            "grade_id": query.grade_id,
            "module_code": course_code,
            "reason": query.reason,
            "status": query.status,
        }
        for query, course_code in query_rows
    ]

    return {
        "assignments": assignments,
        "grades": grades,
        "timetable": timetable,
        "announcements": announcements,
        "grade_queries": grade_queries,
    }