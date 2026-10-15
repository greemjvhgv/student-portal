"""
Owner: Leo (backend: grade-query CRUD endpoints).

This router will handle student grade queries.
Database operations will be implemented once
Adnan's GradeQuery model is available.
"""

from fastapi import APIRouter, Depends, HTTPException
from app.api.deps import require_authenticated_student

router = APIRouter(
    prefix="/grade-queries",
    tags=["grade queries"]
)

@router.post("")
def create_grade_query(
    student=Depends(require_authenticated_student)
):
    raise HTTPException(
        status_code=503,
        detail="Grade queries are not yet available."
    )


@router.get("/{query_id}")
def get_grade_query(
    query_id: int,
    student=Depends(require_authenticated_student)
):
    raise HTTPException(
        status_code=503,
        detail="Grade queries are not yet available."
    )


@router.put("/{query_id}")
def update_grade_query(
    query_id: int,
    student=Depends(require_authenticated_student)
):
    raise HTTPException(
        status_code=503,
        detail="Grade queries are not yet available."
    )


@router.delete("/{query_id}")
def delete_grade_query(
    query_id: int,
    student=Depends(require_authenticated_student)
):
    raise HTTPException(
        status_code=503,
        detail="Grade queries are not yet available."
    )
