"""
Owner: Ofentse (backend: sync service + conflict resolution).

Handles offline assignment-status updates, operation logging,
server-wins conflict resolution, and student sync pulls.
"""

import json
from datetime import datetime, timezone

from app.models.assignment import Assignment
from app.models.announcement import Announcement
from app.models.conflict import Conflict
from app.models.course import Course
from app.models.enrolment import Enrolment
from app.models.grade import Grade
from app.models.submission import Submission
from app.models.sync_metadata import SyncMetadata
from app.models.sync_operation import SyncOperation
from app.models.timetable import Timetable


def _as_utc(value):
    """Normalize timestamps for safe comparison."""
    if value is None:
        return None

    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)

    return value.astimezone(timezone.utc)


def _json(data):
    """Serialize data for the sync log and conflict records."""
    return json.dumps(data, default=str)


def apply_push(db, table_name: str, record_id: int, fields: dict, client_updated_at):
    """
    Apply one offline change.

    The agreed contract currently supports assignment status changes.
    A submission is updated only if exactly one submission exists for
    the assignment, because the payload does not identify a student.
    """

    if table_name != "assignments":
        raise ValueError(
            "Only assignment-status updates are supported by this sync endpoint."
        )

    if not isinstance(fields, dict):
        raise ValueError("The change fields must be an object.")

    status = fields.get("status")

    if status not in {"submitted", "not_submitted"}:
        raise ValueError("Unsupported assignment status.")

    if client_updated_at is None:
        raise ValueError("client_updated_at is required.")

    assignment = (
        db.query(Assignment)
        .filter(Assignment.assignment_id == record_id)
        .first()
    )

    if assignment is None:
        raise ValueError("Assignment not found.")

    submissions = (
        db.query(Submission)
        .filter(Submission.assignment_id == record_id)
        .all()
    )

    # Never guess which student's submission should be changed.
    if len(submissions) != 1:
        raise ValueError(
            "Cannot safely identify the student's submission. "
            "The agreed payload does not include student_id."
        )

    submission = submissions[0]

    metadata = (
        db.query(SyncMetadata)
        .filter(
            SyncMetadata.entity_type == table_name,
            SyncMetadata.entity_id == record_id,
        )
        .first()
    )

    # Prefer sync metadata; fall back to the existing server record.
    server_updated_at = (
        metadata.last_modified_at if metadata else None
    )

    if server_updated_at is None:
        server_updated_at = submission.updated_at

    if server_updated_at is None:
        server_updated_at = assignment.updated_at

    client_time = _as_utc(client_updated_at)
    server_time = _as_utc(server_updated_at)

    operation = SyncOperation(
        entity_type=table_name,
        entity_id=record_id,
        operation_type="push",
        payload=_json({
            "table": table_name,
            "id": record_id,
            **fields,
            "client_updated_at": client_updated_at,
        }),
        status="pending",
        attempts=1,
    )
    db.add(operation)

    # A newer server version wins; preserve it and log the conflict.
    if server_time is not None and server_time > client_time:
        conflict = Conflict(
            entity_type=table_name,
            entity_id=record_id,
            local_version=metadata.local_version if metadata else None,
            server_version=metadata.server_version if metadata else None,
            local_data=_json(fields),
            server_data=_json({
                "assignment_id": assignment.assignment_id,
                "submission_id": submission.submission_id,
                "status": submission.status,
                "updated_at": server_updated_at,
            }),
            resolution_status="server_wins",
        )
        db.add(conflict)

        operation.status = "conflict"

        return {
            "table": table_name,
            "id": record_id,
            "resolution": "server_wins",
        }

    # Apply only the permitted student submission status field.
    submission.status = status

    now = datetime.now(timezone.utc)

    if status == "submitted":
        submission.submitted_at = client_time

    if metadata is None:
        metadata = SyncMetadata(
            entity_type=table_name,
            entity_id=record_id,
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


def pull_changes_since(db, student_id: int):
    """
    Return the current server snapshot for the requested student.

    The existing schema does not store a per-student last-sync
    checkpoint, so this returns the current snapshot rather than
    claiming to return a precise incremental delta.
    """

    student_exists = (
        db.query(Enrolment)
        .filter(Enrolment.student_id == student_id)
        .first()
    )

    if student_exists is None:
        # A student with no enrolments may still exist.
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
                assignment.due_date.date().isoformat()
                if assignment.due_date
                else None
            ),
        }
        for assignment, submission, course_code in assignment_rows
    ]

    grade_rows = (
        db.query(Grade, Course.course_code)
        .join(
            Assignment,
            Grade.assignment_id == Assignment.assignment_id,
        )
        .join(Course, Assignment.course_id == Course.course_id)
        .filter(Grade.student_id == student_id)
        .all()
    )

    grades = [
        {
            "module_code": course_code,
            "mark": grade.mark,
            "updated_at": (
                grade.updated_at.date().isoformat()
                if grade.updated_at
                else None
            ),
        }
        for grade, course_code in grade_rows
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
        }
        for item, course_code in timetable_rows
    ]

    # Include global announcements and announcements for enrolled courses.
    enrolled_course_ids = (
        db.query(Enrolment.course_id)
        .filter(Enrolment.student_id == student_id)
        .subquery()
    )

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

    return {
        "assignments": assignments,
        "grades": grades,
        "timetable": timetable,
        "announcements": announcements,
    }