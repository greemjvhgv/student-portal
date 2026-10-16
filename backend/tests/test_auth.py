import pytest
from fastapi import Depends
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import models  # noqa: F401  (register all tables)
from app.api.deps import get_current_student, require_own_student_id
from app.core.security import create_access_token, hash_password
from app.database import Base, get_db
from app.main import app as real_app
from app.models import Role, Student, User


@real_app.get("/_whoami/{student_id}")
def _whoami(student: Student = Depends(require_own_student_id)):
    return {"student_id": student.student_id}


@real_app.get("/_me")
def _me(student: Student = Depends(get_current_student)):
    return {"student_id": student.student_id}


@pytest.fixture()
def client():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool
    )
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)

    db = Session()
    role = Role(role_name="student")
    db.add(role)
    db.flush()
    for num, first in [("EDUV1234567", "John"), ("EDUV7654321", "Jane")]:
        user = User(email=f"{first}@x.com", password_hash=hash_password("secret123"),
                    role_id=role.role_id)
        db.add(user)
        db.flush()
        db.add(Student(user_id=user.user_id, student_number=num,
                       first_name=first, last_name="Doe"))
    db.commit()
    db.close()

    def override_db():
        s = Session()
        try:
            yield s
        finally:
            s.close()

    real_app.dependency_overrides[get_db] = override_db
    yield TestClient(real_app)
    real_app.dependency_overrides.clear()


def login(client, number="EDUV1234567", password="secret123"):
    return client.post("/auth/login", json={"student_number": number, "password": password})


def test_login_success(client):
    r = login(client)
    assert r.status_code == 200
    body = r.json()
    assert body["full_name"] == "John Doe"
    assert body["student_id"] == 1
    assert body["token"]


def test_login_case_insensitive_number(client):
    assert login(client, number="eduv1234567").status_code == 200


def test_login_wrong_password(client):
    r = login(client, password="nope")
    assert r.status_code == 401
    assert r.json()["detail"] == "Invalid student number or password"


def test_login_unknown_student_same_error(client):
    r = login(client, number="EDUV0000000")
    assert r.status_code == 401
    assert r.json()["detail"] == "Invalid student number or password"


def test_protected_route_requires_token(client):
    assert client.get("/_me").status_code == 401


def test_protected_route_with_token(client):
    token = login(client).json()["token"]
    r = client.get("/_me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200 and r.json()["student_id"] == 1


def test_expired_token_rejected(client):
    token = create_access_token(1, expires_minutes=-1)
    r = client.get("/_me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 401


def test_garbage_token_rejected(client):
    r = client.get("/_me", headers={"Authorization": "Bearer abc.def.ghi"})
    assert r.status_code == 401


def test_cannot_access_other_students_id(client):
    token = login(client).json()["token"]
    h = {"Authorization": f"Bearer {token}"}
    assert client.get("/_whoami/1", headers=h).status_code == 200
    assert client.get("/_whoami/2", headers=h).status_code == 403
