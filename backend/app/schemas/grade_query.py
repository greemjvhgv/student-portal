"""
Owner: Leo
Pydantic schemas for student grade queries.
"""

from pydantic import BaseModel, Field


class GradeQueryCreate(BaseModel):
    grade_id: int
    reason: str = Field(min_length=10, max_length=1000)


class GradeQueryUpdate(BaseModel):
    reason: str = Field(min_length=10, max_length=1000)


class GradeQueryResponse(BaseModel):
    query_id: int
    student_id: int
    grade_id: int
    reason: str
    status: str

    model_config = {"from_attributes": True}
