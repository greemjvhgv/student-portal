"""Owner: Ruan. Request/response shapes for /auth — match docs/API_CONTRACT.md."""
from pydantic import BaseModel


class LoginRequest(BaseModel):
    student_number: str
    password: str


class LoginResponse(BaseModel):
    token: str
    student_id: int
    full_name: str
