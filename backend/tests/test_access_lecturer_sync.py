"""
Owner: Annuschka (integration).

Tests for: student routes locked behind login (own data only), the
lecturer endpoints (US08-US10), and sync push using the logged-in student,
including the server-wins conflict rule (FR11-FR13) and safe retries.
Run from backend/:  .\\.venv\\Scripts\\python.exe -m pytest
"""
from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import models  # noqa: F401  (register all tables)
from app.core.security import hash_password
from app.database import Base, get_db
from app.main import app
from app.models import (
    Assignment,
    Course,
    Enrolment,
    Grade,
    LecturerAdmin,
    Role,
    Student,
    Submission,
    User,
)

PASSWORD = "secret123"


@pytest.fixture()
def client():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)

    db = Session()
    student_role = Role(role_name="student")
    lecturer_role = Role(role_name="lecturer")
    db.add_all([student_role, lecturer_role])
    db.flush()

    lecturer_user = User(email="lecturer@x.com", password_hash=hash_password(PASSWORD),
                         role_id=lecturer_role.role_id)
    db.add(lecturer_user)
    db.flush()
    lecturer = LecturerAdmin(user_id=lecturer_user.user_id, first_name="Test",
                             last_name="Lecturer")
    db.add(lecturer)
    db.flush()

    course = Course(course_code="ITMDA3-34", course_name="Project",
                    lecturer_id=lecturer.lecturer_id)
    db.add(course)
    db.flush()
    assignment = Assignment(course_id=course.course_id, title="Deliverable 4",
                            due_date=datetime.now(timezone.utc) + timedelta(days=7))
    db.add(assignment)
    db.flush()

    for number, first in [("EDUV1111111", "Ann"), ("EDUV2222222", "Ben")]:
        user = User(email=f"{first}@x.com", password_hash=hash_password(PASSWORD),
                    role_id=student_role.role_id)
        db.add(user)
        db.flush()
        student = Student(user_id=user.user_id, student_number=number,
                          first_name=first, last_name="Test")
        db.add(student)
        db.flush()
        db.add(Enrolment(student_id=student.student_id, course_id=course.course_id))
        db.add(Submission(assignment_id=assignment.assignment_id,
                          student_id=student.student_id, status="not_submitted"))
        db.add(Grade(assignment_id=assignment.assignment_id,
                     student_id=student.student_id, mark=70.0))
    db.commit()
    db.close()

    def override_db():
        session = Session()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_db
    yield TestClient(app)
    app.dependency_overrides.clear()


def student_headers(client, number="EDUV1111111"):
    token = client.post("/auth/login", json={"student_number": number,
                                             "password": PASSWORD}).json()["token"]
    return {"Authorization": f"Bearer {token}"}


def lecturer_headers(client):
    r = client.post("/lecturer/login", json={"email": "lecturer@x.com",
                                             "password": PASSWORD})
    assert r.status_code == 200
    return {"Authorization": f"Bearer {r.json()['token']}"}


def push(client, headers, client_time, status="submitted"):
    return client.post("/sync/push", headers=headers, json=[{
        "table": "assignments", "id": 1, "status": status,
        "client_updated_at": client_time.isoformat(),
    }])


def submission_status(client, lecturer, student_number):
    rows = client.get("/lecturer/submissions", headers=lecturer).json()
    return next(r["status"] for r in rows if r["student_number"] == student_number)


# --------------------------------------------------------------- Access

def test_student_routes_need_login(client):
    assert client.get("/grades/1").status_code == 401
    assert client.get("/announcements").status_code == 401
    assert client.get("/sync/pull/1").status_code == 401


def test_student_sees_only_own_data(client):
    h = student_headers(client)
    assert client.get("/grades/1", headers=h).status_code == 200
    assert client.get("/grades/2", headers=h).status_code == 403
    assert client.get("/sync/pull/2", headers=h).status_code == 403


def test_tokens_are_not_interchangeable(client):
    student = student_headers(client)
    lecturer = lecturer_headers(client)
    assert client.get("/lecturer/grades", headers=student).status_code == 401
    assert client.get("/grades/1", headers=lecturer).status_code == 401


def test_lecturer_wrong_password(client):
    r = client.post("/lecturer/login", json={"email": "lecturer@x.com",
                                             "password": "nope"})
    assert r.status_code == 401


# ------------------------------------------------------------- Lecturer

def test_lecturer_updates_grade(client):
    lecturer = lecturer_headers(client)
    r = client.put("/lecturer/grades/1", headers=lecturer, json={"mark": 90})
    assert r.status_code == 200 and r.json()["mark"] == 90
    grades = client.get("/grades/1", headers=student_headers(client)).json()
    assert grades[0]["mark"] == 90


def test_lecturer_announcement_crud(client):
    lecturer = lecturer_headers(client)
    student = student_headers(client)
    created = client.post("/lecturer/announcements", headers=lecturer,
                          json={"title": "Test notice", "content": "Hello"})
    assert created.status_code == 201
    announcement_id = created.json()["announcement_id"]
    assert client.put(f"/lecturer/announcements/{announcement_id}", headers=lecturer,
                      json={"content": "Updated"}).status_code == 200
    titles = [a["title"] for a in client.get("/announcements", headers=student).json()]
    assert "Test notice" in titles
    assert client.delete(f"/lecturer/announcements/{announcement_id}",
                         headers=lecturer).status_code == 204
    titles = [a["title"] for a in client.get("/announcements", headers=student).json()]
    assert "Test notice" not in titles


# ----------------------------------------------------------------- Sync

def test_push_updates_only_own_submission(client):
    r = push(client, student_headers(client), datetime.now(timezone.utc))
    assert r.status_code == 200 and r.json()["conflicts"] == []
    lecturer = lecturer_headers(client)
    assert submission_status(client, lecturer, "EDUV1111111") == "submitted"
    assert submission_status(client, lecturer, "EDUV2222222") == "not_submitted"


def test_push_retry_is_ignored(client):
    h = student_headers(client)
    client_time = datetime.now(timezone.utc)
    assert push(client, h, client_time).json()["conflicts"] == []
    retry = push(client, h, client_time)
    assert retry.status_code == 200 and retry.json()["conflicts"] == []


def test_newer_lecturer_change_wins_conflict(client):
    h = student_headers(client)
    offline_change_time = datetime.now(timezone.utc)
    lecturer = lecturer_headers(client)
    # The lecturer reopens the submission after the student's offline change.
    assert client.put("/lecturer/submissions/1", headers=lecturer,
                      json={"status": "not_submitted"}).status_code == 200
    r = push(client, h, offline_change_time)
    assert r.status_code == 200
    conflicts = r.json()["conflicts"]
    assert len(conflicts) == 1 and conflicts[0]["resolution"] == "server_wins"
    assert submission_status(client, lecturer, "EDUV1111111") == "not_submitted"
