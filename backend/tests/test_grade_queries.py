import pytest

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import models
from app.database import Base, get_db
from app.main import app
from app.core.security import create_access_token
from app.models import (
    Role,
    User,
    Student,
    Course,
    Assignment,
    Grade,
    GradeQuery,
)


@pytest.fixture()
def db():
    """Create a fresh SQLite database for each test."""

    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine)

    session = TestingSession()

    try:
        yield session
    finally:
        session.close()
        engine.dispose()

@pytest.fixture()
def test_client(db):
    """Connect FastAPI to the isolated test database."""

    def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db

    try:
        with TestClient(app) as client:
            yield client
    finally:
        app.dependency_overrides.pop(get_db, None)

@pytest.fixture
def sample_grade_data(db):
    """Create two students and grades for ownership tests."""

    role = Role(role_name="student")
    db.add(role)
    db.flush()

    user1 = User(
        email="student1@example.com",
        password_hash="test_hash_1",
        role_id=role.role_id,
    )

    user2 = User(
        email="student2@example.com",
        password_hash="test_hash_2",
        role_id=role.role_id,
    )

    db.add_all([user1, user2])
    db.flush()

    student1 = Student(
        user_id=user1.user_id,
        student_number="TEST001",
        first_name="Student",
        last_name="One",
    )

    student2 = Student(
        user_id=user2.user_id,
        student_number="TEST002",
        first_name="Student",
        last_name="Two",
    )

    db.add_all([student1, student2])
    db.flush()

    course = Course(
        course_code="TEST101",
        course_name="Test Software Engineering",
    )

    db.add(course)
    db.flush()

    assignment = Assignment(
        course_id=course.course_id,
        title="Test Assignment",
        description="Assignment for Grade Query testing",
    )

    db.add(assignment)
    db.flush()

    grade1 = Grade(
        assignment_id=assignment.assignment_id,
        student_id=student1.student_id,
        mark=75.0,
        grade_value="75%",
    )

    grade2 = Grade(
        assignment_id=assignment.assignment_id,
        student_id=student2.student_id,
        mark=85.0,
        grade_value="85%",
    )

    db.add_all([grade1, grade2])
    db.commit()

    return {
        "student1": student1,
        "student2": student2,
        "grade1": grade1,
        "grade2": grade2,
    }
def test_student_can_create_grade_query(
    test_client,
    sample_grade_data,
):
    """An authenticated student can query their own grade."""

    student = sample_grade_data["student1"]
    grade = sample_grade_data["grade1"]

    token = create_access_token(student.student_id)

    response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade.grade_id,
            "reason": "I would like my assignment mark reviewed.",
        },
        headers={
            "Authorization": f"Bearer {token}",
        },
    )
    assert response.status_code == 201

    data = response.json()

    assert data["student_id"] == student.student_id
    assert data["grade_id"] == grade.grade_id
    assert data["status"] == "pending"
    assert data["reason"] == "I would like my assignment mark reviewed."

def test_student_cannot_query_another_students_grade(
    test_client,
    sample_grade_data,
):
    """Students cannot query grades belonging to other students."""

    student1 = sample_grade_data["student1"]
    grade2 = sample_grade_data["grade2"]

    token = create_access_token(student1.student_id)

    response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade2.grade_id,
            "reason": "I would like this assignment grade reviewed.",
        },
        headers={
            "Authorization": f"Bearer {token}",
        },
    )

    assert response.status_code == 403

    assert response.json()["detail"] == (
        "You cannot query another student's grade."
    )

def test_student_can_get_own_grade_query(
    test_client,
    sample_grade_data,
):
    """Students can retrieve their own grade queries."""

    student = sample_grade_data["student1"]
    grade = sample_grade_data["grade1"]

    token = create_access_token(student.student_id)

    headers = {
        "Authorization": f"Bearer {token}",
    }

    # Create a Grade Query first.
    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade.grade_id,
            "reason": "Please review my assignment grade.",
        },
        headers=headers,
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Retrieve the newly created Grade Query.
    response = test_client.get(
        f"/grade-queries/{query_id}",
        headers=headers,
    )

    assert response.status_code == 200

    data = response.json()

    assert data["query_id"] == query_id
    assert data["student_id"] == student.student_id
    assert data["grade_id"] == grade.grade_id
    assert data["status"] == "pending"

def test_student_cannot_get_another_students_grade_query(
    test_client,
    sample_grade_data,
):
    """Students cannot retrieve another student's grade query."""

    student1 = sample_grade_data["student1"]
    student2 = sample_grade_data["student2"]
    grade1 = sample_grade_data["grade1"]

    # Student 1 creates a Grade Query.
    token1 = create_access_token(student1.student_id)

    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade1.grade_id,
            "reason": "Please review my assignment grade.",
        },
        headers={
            "Authorization": f"Bearer {token1}",
        },
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Student 2 attempts to retrieve Student 1's Grade Query.
    token2 = create_access_token(student2.student_id)

    response = test_client.get(
        f"/grade-queries/{query_id}",
        headers={
            "Authorization": f"Bearer {token2}",
        },
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Grade query not found."

def test_student_can_update_own_grade_query(
    test_client,
    sample_grade_data,
):
    """Students can update the reason for their own grade queries."""

    student = sample_grade_data["student1"]
    grade = sample_grade_data["grade1"]

    token = create_access_token(student.student_id)

    headers = {
        "Authorization": f"Bearer {token}",
    }

    # Create a Grade Query.
    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade.grade_id,
            "reason": "Please review my original assignment mark.",
        },
        headers=headers,
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Update the Grade Query reason.
    updated_reason = "I believe my assignment deserves a second review."

    response = test_client.put(
        f"/grade-queries/{query_id}",
        json={
            "reason": updated_reason,
        },
        headers=headers,
    )

    assert response.status_code == 200

    data = response.json()

    assert data["query_id"] == query_id
    assert data["student_id"] == student.student_id
    assert data["reason"] == updated_reason

    # Verify the updated reason was saved.
    get_response = test_client.get(
        f"/grade-queries/{query_id}",
        headers=headers,
    )

    assert get_response.status_code == 200
    assert get_response.json()["reason"] == updated_reason

def test_student_cannot_update_another_students_grade_query(
    test_client,
    sample_grade_data,
):
    """Students cannot update another student's grade query."""

    student1 = sample_grade_data["student1"]
    student2 = sample_grade_data["student2"]
    grade1 = sample_grade_data["grade1"]

    # Student 1 creates their own Grade Query.
    token1 = create_access_token(student1.student_id)

    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade1.grade_id,
            "reason": "Please review my original assignment grade.",
        },
        headers={
            "Authorization": f"Bearer {token1}",
        },
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Student 2 attempts to update Student 1's query.
    token2 = create_access_token(student2.student_id)

    response = test_client.put(
        f"/grade-queries/{query_id}",
        json={
            "reason": "This grade query has been changed by another student.",
        },
        headers={
            "Authorization": f"Bearer {token2}",
        },
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Grade query not found."

    # Confirm Student 1's original reason remains unchanged.
    get_response = test_client.get(
        f"/grade-queries/{query_id}",
        headers={
            "Authorization": f"Bearer {token1}",
        },
    )

    assert get_response.status_code == 200
    assert (
        get_response.json()["reason"]
        == "Please review my original assignment grade."
    )

def test_student_can_delete_own_grade_query(
    test_client,
    sample_grade_data,
):
    """Students can delete their own pending grade queries."""

    student = sample_grade_data["student1"]
    grade = sample_grade_data["grade1"]

    token = create_access_token(student.student_id)

    headers = {
        "Authorization": f"Bearer {token}",
    }

    # Create a Grade Query.
    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade.grade_id,
            "reason": "Please review my assignment grade.",
        },
        headers=headers,
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Delete the pending Grade Query.
    response = test_client.delete(
        f"/grade-queries/{query_id}",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["query_id"] == query_id

    # Confirm the deleted Grade Query no longer exists.
    get_response = test_client.get(
        f"/grade-queries/{query_id}",
        headers=headers,
    )

    assert get_response.status_code == 404
    assert get_response.json()["detail"] == "Grade query not found."

def test_student_cannot_delete_another_students_grade_query(
    test_client,
    sample_grade_data,
):
    """Students cannot delete another student's grade query."""

    student1 = sample_grade_data["student1"]
    student2 = sample_grade_data["student2"]
    grade1 = sample_grade_data["grade1"]

    # Student 1 creates a Grade Query.
    token1 = create_access_token(student1.student_id)

    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade1.grade_id,
            "reason": "Please review my assignment grade.",
        },
        headers={
            "Authorization": f"Bearer {token1}",
        },
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Student 2 attempts to delete Student 1's Grade Query.
    token2 = create_access_token(student2.student_id)

    response = test_client.delete(
        f"/grade-queries/{query_id}",
        headers={
            "Authorization": f"Bearer {token2}",
        },
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Grade query not found."

    # Confirm Student 1's Grade Query still exists.
    get_response = test_client.get(
        f"/grade-queries/{query_id}",
        headers={
            "Authorization": f"Bearer {token1}",
        },
    )

    assert get_response.status_code == 200
    assert get_response.json()["query_id"] == query_id

def test_student_cannot_delete_resolved_grade_query(
    test_client,
    sample_grade_data,
    db,
):
    """A student cannot delete a resolved Grade Query."""

    student = sample_grade_data["student1"]
    grade = sample_grade_data["grade1"]

    token = create_access_token(student.student_id)

    # Create a Grade Query.
    create_response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade.grade_id,
            "reason": "Please review my assignment mark.",
        },
        headers={
            "Authorization": f"Bearer {token}",
        },
    )

    assert create_response.status_code == 201

    query_id = create_response.json()["query_id"]

    # Simulate the Grade Query being resolved.
    grade_query = db.get(GradeQuery, query_id)
    grade_query.status = "resolved"
    db.commit()

    # Attempt to delete the resolved Grade Query.
    response = test_client.delete(
        f"/grade-queries/{query_id}",
        headers={
            "Authorization": f"Bearer {token}",
        },
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "Only pending grade queries can be deleted."
    )

    # Verify that the Grade Query still exists.
    db.expire_all()
    saved_query = db.get(GradeQuery, query_id)

    assert saved_query is not None
    assert saved_query.status == "resolved"

def test_unauthenticated_student_cannot_access_grade_queries(
    test_client,
):
    """Grade Query endpoints require student authentication."""

    requests = [
        test_client.post(
            "/grade-queries",
            json={
                "grade_id": 1,
                "reason": "Please review my assignment grade.",
            },
        ),
        test_client.get("/grade-queries/1"),
        test_client.put(
            "/grade-queries/1",
            json={
                "reason": "I would like my mark reviewed again.",
            },
        ),
        test_client.delete("/grade-queries/1"),
    ]

    for response in requests:
        assert response.status_code == 401
        assert response.json()["detail"] == "Not authenticated"

def test_student_cannot_create_grade_query_with_short_reason(
    test_client,
    sample_grade_data,
):
    """Reject Grade Queries with reasons shorter than 10 characters."""

    student = sample_grade_data["student1"]
    grade = sample_grade_data["grade1"]

    token = create_access_token(student.student_id)

    response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": grade.grade_id,
            "reason": "Short",
        },
        headers={
            "Authorization": f"Bearer {token}",
        },
    )

    assert response.status_code == 422

def test_student_cannot_query_nonexistent_grade(
    test_client,
    sample_grade_data,
):
    """Reject Grade Queries for grades that do not exist."""

    student = sample_grade_data["student1"]

    token = create_access_token(student.student_id)

    response = test_client.post(
        "/grade-queries",
        json={
            "grade_id": 999999,
            "reason": "I would like this assignment grade reviewed.",
        },
        headers={
            "Authorization": f"Bearer {token}",
        },
    )

    assert response.status_code == 404