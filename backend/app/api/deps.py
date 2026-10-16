"""
Owner: Ruan (backend: authentication).

get_current_student: use as `Depends(get_current_student)` on any route that
needs a logged-in student. require_own_student_id additionally checks that
the {student_id} in the URL belongs to the caller.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.database import get_db
from app.models.student import Student

bearer_scheme = HTTPBearer(auto_error=False)


def get_current_student(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Student:
    unauthorized = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Not authenticated",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise unauthorized
    student_id = decode_access_token(credentials.credentials)
    if student_id is None:
        raise unauthorized
    student = db.get(Student, student_id)
    if student is None:
        raise unauthorized
    return student


def require_own_student_id(
    student_id: int, student: Student = Depends(get_current_student)
) -> Student:
    if student.student_id != student_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    return student
