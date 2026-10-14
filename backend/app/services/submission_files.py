

from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile

# Store uploaded files outside the application source directory.
UPLOAD_DIR = Path(__file__).resolve().parents[2] / "uploads" / "submissions"

# Maximum permitted upload size: 10 MB
MAX_FILE_SIZE = 10 * 1024 * 1024

ALLOWED_EXTENSIONS = {".pdf", ".docx", ".txt"}


async def save_submission_file(file: UploadFile) -> str:
    """Validate and save a student submission file."""

    extension = Path(file.filename or "").suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Only PDF, DOCX and TXT files are allowed."
        )

    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    file_path = UPLOAD_DIR / f"{uuid4().hex}{extension}"
    total_size = 0

    try:
        with file_path.open("xb") as destination:
            while chunk := await file.read(1024 * 1024):
                total_size += len(chunk)

                if total_size > MAX_FILE_SIZE:
                    raise HTTPException(
                        status_code=413,
                        detail="File exceeds the 10 MB limit."
                    )

                destination.write(chunk)

        return str(file_path.relative_to(UPLOAD_DIR.parent.parent))

    except Exception:
        file_path.unlink(missing_ok=True)
        raise

    finally:
        await file.close()


def delete_submission_file(file_path: str | None) -> None:
    """Delete a previously stored submission file."""

    if not file_path:
        return

    root = UPLOAD_DIR.resolve()
    target = (root.parent.parent / file_path).resolve()

    # Prevent deletion of files outside the submission directory.
    if not target.is_relative_to(root) or target == root:
        raise ValueError("Invalid submission file path.")

    target.unlink(missing_ok=True)
