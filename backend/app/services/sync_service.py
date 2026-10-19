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


def apply_push(
    db,
    student_id: int,
    table_name: str,
    record_id: int,
    fields: dict,
    client_updated_at,
):
    """
    Apply one offline change made by the logged-in student.

    Supports assignment status changes (US05). The change is applied to
    this student's own Submission for the assignment (student_id comes from
    the login token, see app/routers/sync.py).

    Conflict rule (FR11-FR13, US06): if the server's copy of the submission
    changed after the student made the change offline, the server wins:
    nothing is applied, both sides are saved in Conflict, and the conflict
    is returned to the app.

    Pushing the same change again (e.g. the reply was lost when the
    connection dropped and the phone retried) is ignored, so retries never
    create duplicates or false conflicts (D3 Reliability).
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

    # Same change already applied earlier: nothing to do.
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

    # A newer server version wins; preserve it and log the conflict.
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

    # Apply only the permitted student submission status field.
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

    return {
        "assignments": assignments,
        "grades": grades,
        "timetable": timetable,
        "announcements": announcements,
    }