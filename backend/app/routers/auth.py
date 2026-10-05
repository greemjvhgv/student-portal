"""
Owner: Ruan (backend: project structure + authentication).

POST /auth/login — see docs/API_CONTRACT.md for the exact request/response
shape. TODO:
  - look up the Student by student_number, then the linked User for the
    password hash
  - verify the password (use passlib's bcrypt — don't compare plaintext)
  - issue a token (a real JWT with expiry, not just a random string)
"""
from fastapi import APIRouter

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login")
def login():
    raise NotImplementedError("TODO (Ruan): implement login per docs/API_CONTRACT.md")
