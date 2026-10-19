"""
Owner: Annuschka (integration), built on Ruan's get_current_student.

require_student_access is added to every student router in app/main.py:
  - the request must carry a valid student login token (401 otherwise);
  - if the URL contains {student_id}, it must be the logged-in student's
    own id (403 otherwise), so students can only read their own data
    (D3 Safety NFR 3: access restricted to authenticated users).
"""
from fastapi import Depends, HTTPException, Request, status

from app.api.deps import get_current_student
from app.models.student import Student


def require_student_access(
    request: Request, student: Student = Depends(get_current_student)
) -> Student:
    requested_id = request.path_params.get("student_id")
    if requested_id is not None and str(requested_id) != str(student.student_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
    return student
