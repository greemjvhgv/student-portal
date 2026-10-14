

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
    """Replace a submission file after verifying student ownership."""

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

    # Remove the previous file only after the database commit.
    if old_file_path and old_file_path != new_file_path:
        delete_submission_file(old_file_path)

    return {
        "message": "Submission updated successfully.",
        "submission_id": submission.submission_id,
        "status": submission.status,
        "file_path": submission.file_path,
    }

def delete_student_submission(
    submission_id: int,
    student_id: int,
    db: Session,
):
    """Delete a submission belonging to the verified student."""

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
        db.delete(submission)
        db.commit()
    except Exception:
        db.rollback()
        raise

    # Delete the stored file only after the database commit.
    if old_file_path:
        delete_submission_file(old_file_path)

    return {
        "message": "Submission deleted successfully.",
        "submission_id": submission_id,
    }
