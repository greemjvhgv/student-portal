"""
Owner: Leo. Tests for the submissions module: replacing a file (update)
and withdrawing (delete), only for the logged-in student's own submissions.
"""

import pytest

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import models  # Register SQLAlchemy models
from app.database import Base, get_db
from app.main import app
from app.services import submission_files
from app.core.security import create_access_token
from app.models import Role, User, Student, Course, Assignment, Submission


@pytest.fixture()
def client(tmp_path, monkeypatch):
    """Create an isolated database and upload folder for each test."""

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    # Create sample students, assignments and submissions.
    db = TestingSession()
    try:
        test_data = create_test_data(db)
    finally:
        db.close()

    app.dependency_overrides[get_db] = override_get_db

    # Keep uploaded test files separate from real submissions.
    monkeypatch.setattr(
        submission_files,
        "UPLOAD_DIR",
        tmp_path / "uploads" / "submissions",
    )

    try:
        yield TestClient(app), test_data
    finally:
        app.dependency_overrides.clear()
        engine.dispose()


def create_test_data(db):
    """Create two students with separate assignment submissions."""

    role = Role(role_name="student")
    db.add(role)
    db.flush()

    students = []

    for number, name in [
        ("EDUV1234567", "John"),
        ("EDUV7654321", "Jane"),
    ]:
        user = User(
            email=f"{name.lower()}@example.com",
            password_hash="test-password-hash",
            role_id=role.role_id,
        )
        db.add(user)
        db.flush()

        student = Student(
            user_id=user.user_id,
            student_number=number,
            first_name=name,
            last_name="Doe",
        )
        db.add(student)
        db.flush()
        students.append(student)

    course = Course(
        course_code="SWE101",
        course_name="Software Engineering",
    )
    db.add(course)
    db.flush()

    assignment = Assignment(
        course_id=course.course_id,
        title="Database Assignment",
    )
    db.add(assignment)
    db.flush()

    submissions = []

    for student in students:
        submission = Submission(
            assignment_id=assignment.assignment_id,
            student_id=student.student_id,
            status="submitted",
        )
        db.add(submission)
        db.flush()
        submissions.append(submission)

    result = {
        "student_ids": [student.student_id for student in students],
        "submission_ids": [
            submission.submission_id for submission in submissions
        ],
    }

    db.commit()
    return result


def test_student_can_update_own_submission(client):
    """Verify that a student can replace their own submission file."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    submission_id = test_data["submission_ids"][0]

    token = create_access_token(student_id)

    response = test_client.put(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
        files={
            "file": (
                "assignment.txt",
                b"Updated assignment content",
                "text/plain",
            )
        },
    )

    assert response.status_code == 200
    assert response.json()["status"] == "submitted"
    assert response.json()["submission_id"] == submission_id


def test_student_cannot_update_another_students_submission(client):
    """Prevent students from replacing another student's submission."""

    test_client, test_data = client

    john_id = test_data["student_ids"][0]
    jane_submission_id = test_data["submission_ids"][1]

    token = create_access_token(john_id)

    response = test_client.put(
        f"/assignments/submissions/{jane_submission_id}",
        headers={"Authorization": f"Bearer {token}"},
        files={
            "file": (
                "assignment.txt",
                b"Attempted unauthorised update",
                "text/plain",
            )
        },
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Submission not found."


def test_student_can_withdraw_own_submission(client):
    """Verify that a student can withdraw their own submission. The record
    is kept as "not_submitted", so withdrawing again is harmless."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    submission_id = test_data["submission_ids"][0]

    token = create_access_token(student_id)

    response = test_client.delete(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()["message"] == "Submission withdrawn successfully."
    assert response.json()["submission_id"] == submission_id
    assert response.json()["status"] == "not_submitted"

    # The record still exists, so a second withdraw also succeeds.
    second_response = test_client.delete(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert second_response.status_code == 200


def test_student_cannot_delete_another_students_submission(client):
    """Prevent students from deleting another student's submission."""

    test_client, test_data = client

    john_id = test_data["student_ids"][0]
    jane_submission_id = test_data["submission_ids"][1]

    token = create_access_token(john_id)

    response = test_client.delete(
        f"/assignments/submissions/{jane_submission_id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Submission not found."

    # Confirm Jane's submission still exists by attempting
    # to delete it using Jane's own authenticated token.
    jane_id = test_data["student_ids"][1]
    jane_token = create_access_token(jane_id)

    jane_response = test_client.delete(
        f"/assignments/submissions/{jane_submission_id}",
        headers={"Authorization": f"Bearer {jane_token}"},
    )

    assert jane_response.status_code == 200


def test_student_cannot_upload_invalid_file_type(client):
    """Reject unsupported assignment submission file formats."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    submission_id = test_data["submission_ids"][0]

    token = create_access_token(student_id)

    response = test_client.put(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
        files={
            "file": (
                "malicious.exe",
                b"Invalid executable content",
                "application/octet-stream",
            )
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Only PDF, DOCX and TXT files are allowed."
    )


def test_student_cannot_upload_file_larger_than_10mb(client):
    """Reject submission files exceeding the 10 MB limit."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    submission_id = test_data["submission_ids"][0]

    token = create_access_token(student_id)

    oversized_file = b"A" * (10 * 1024 * 1024 + 1)

    response = test_client.put(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
        files={
            "file": (
                "large_assignment.txt",
                oversized_file,
                "text/plain",
            )
        },
    )

    assert response.status_code == 413
    assert response.json()["detail"] == "File exceeds the 10 MB limit."


def test_student_cannot_update_nonexistent_submission(client):
    """Return HTTP 404 when the submission does not exist."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    token = create_access_token(student_id)

    response = test_client.put(
        "/assignments/submissions/999999",
        headers={"Authorization": f"Bearer {token}"},
        files={
            "file": (
                "assignment.txt",
                b"Updated assignment content",
                "text/plain",
            )
        },
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Submission not found."


def test_student_cannot_delete_nonexistent_submission(client):
    """Return HTTP 404 when deleting a missing submission."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    token = create_access_token(student_id)

    response = test_client.delete(
        "/assignments/submissions/999999",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Submission not found."


def test_withdrawing_submission_removes_uploaded_file(client):
    """Withdrawing a submission must also remove its stored file."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    submission_id = test_data["submission_ids"][0]
    token = create_access_token(student_id)

    # First, upload a file to the existing submission.
    update_response = test_client.put(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
        files={
            "file": (
                "cleanup_test.txt",
                b"Temporary assignment file",
                "text/plain",
            )
        },
    )

    assert update_response.status_code == 200

    # Verify the uploaded file exists.
    stored_path = (
        submission_files.UPLOAD_DIR.parent.parent
        / update_response.json()["file_path"]
    )

    assert stored_path.exists()

    # Withdraw the submission.
    delete_response = test_client.delete(
        f"/assignments/submissions/{submission_id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert delete_response.status_code == 200

    # The uploaded file must no longer exist.
    assert not stored_path.exists()


def test_replacing_submission_removes_previous_file(client):
    """Replacing a submission must remove its previous file."""

    test_client, test_data = client

    student_id = test_data["student_ids"][0]
    submission_id = test_data["submission_ids"][0]
    token = create_access_token(student_id)

    headers = {"Authorization": f"Bearer {token}"}
    url = f"/assignments/submissions/{submission_id}"

    # Upload the first file.
    first_response = test_client.put(
        url,
        headers=headers,
        files={
            "file": (
                "original.txt",
                b"Original assignment content",
                "text/plain",
            )
        },
    )

    assert first_response.status_code == 200

    first_path = (
        submission_files.UPLOAD_DIR.parent.parent
        / first_response.json()["file_path"]
    )

    assert first_path.exists()

    # Replace the original file with a newer version.
    second_response = test_client.put(
        url,
        headers=headers,
        files={
            "file": (
                "updated.txt",
                b"Updated assignment content",
                "text/plain",
            )
        },
    )

    assert second_response.status_code == 200

    second_path = (
        submission_files.UPLOAD_DIR.parent.parent
        / second_response.json()["file_path"]
    )

    # The new file must exist.
    assert second_path.exists()

    # The original file must have been removed.
    assert not first_path.exists()

    # The two uploads must have different file paths.
    assert first_path != second_path
