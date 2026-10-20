"""
Owner: Leo (backend: submission management).

Replace a student's submission file (update) and withdraw a submission
(delete) – always only for the logged-in student's own submission.
"""

from datetime import datetime, timezone

from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.models.submission import Submission
from app.services.submission_files import (
    save_submission_file,
    delete_submission_file,
)


async def replace_submission_file(
    submission_id: int,
    student_id: int,
    file: UploadFile,
    db: Session,
):

    submission = (
        db.query(Submission)
        .filter(
            Submission.submission_id == submission_id,
            Submission.student_id == student_id,
        )
        .first()
    )

    if submission is None:
        raise HTTPException(
            status_code=404,
            detail="Submission not found."
        )

    old_file_path = submission.file_path
    new_file_path = await save_submission_file(file)

    try:
        submission.file_path = new_file_path
        submission.status = "submitted"
        submission.submitted_at = datetime.now(timezone.utc)

        db.commit()
        db.refresh(submission)

    except Exception:
        db.rollback()
        delete_submission_file(new_file_path)
        raise

    if old_file_path and old_file_path != new_file_path:
        delete_submission_file(old_file_path)

    return {
        "message": "Submission updated successfully.",
        "submission_id": submission.submission_id,
        "status": submission.status,
        "file_path": submission.file_path,
    }

def withdraw_student_submission(
    submission_id: int,
    student_id: int,
    db: Session,
):
    submission = (
        db.query(Submission)
        .filter(
            Submission.submission_id == submission_id,
            Submission.student_id == student_id,
        )
        .first()
    )

    if submission is None:
        raise HTTPException(
            status_code=404,
            detail="Submission not found."
        )

    old_file_path = submission.file_path

    try:
        submission.status = "not_submitted"
        submission.file_path = None
        submission.submitted_at = None
        db.commit()
    except Exception:
        db.rollback()
        raise

    if old_file_path:
        delete_submission_file(old_file_path)

    return {
        "message": "Submission withdrawn successfully.",
        "submission_id": submission_id,
        "status": "not_submitted",
    }