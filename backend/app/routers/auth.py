"""
Owner: Ruan (backend: project structure + authentication).

POST /auth/login — see docs/API_CONTRACT.md for the request/response shape.
"""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.security import create_access_token, hash_password, verify_password
from app.database import get_db
from app.models.student import Student
from app.models.user import User
from app.schemas.auth import LoginRequest, LoginResponse

router = APIRouter(prefix="/auth", tags=["auth"])

_DUMMY_HASH = hash_password("not-a-real-password")


@router.post("/login", response_model=LoginResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    student = (
        db.query(Student)
        .filter(Student.student_number == body.student_number.strip().upper())
        .first()
    )
    user = db.get(User, student.user_id) if student else None

    password_ok = verify_password(body.password, user.password_hash if user else _DUMMY_HASH)
    if not (student and user and password_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid student number or password",
        )

    user.last_login = datetime.now(timezone.utc)
    db.commit()

    return LoginResponse(
        token=create_access_token(student.student_id),
        student_id=student.student_id,
        full_name=f"{student.first_name} {student.last_name}",
    )
