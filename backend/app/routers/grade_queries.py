"""
Owner: Leo (backend: grade-query CRUD endpoints).

This router will handle student grade queries.
Database operations will be implemented once
Adnan's GradeQuery model is available.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_current_student
from app.database import get_db
from app.models import Grade, GradeQuery
from app.schemas.grade_query import (
    GradeQueryCreate,
    GradeQueryUpdate,
    GradeQueryResponse,
)

router = APIRouter(
    prefix="/grade-queries",
    tags=["grade queries"]
)

@router.post("", response_model=GradeQueryResponse, status_code=201)
def create_grade_query(
    payload: GradeQueryCreate,
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
    """Create a grade query for the authenticated student's own grade."""

    grade = db.get(Grade, payload.grade_id)

    if grade is None:
        raise HTTPException(
            status_code=404,
            detail="Grade not found.",
        )

    if grade.student_id != student.student_id:
        raise HTTPException(
            status_code=403,
            detail="You cannot query another student's grade.",
        )

    grade_query = GradeQuery(
        student_id=student.student_id,
        grade_id=payload.grade_id,
        reason=payload.reason,
        status="pending",
    )

    db.add(grade_query)
    db.commit()
    db.refresh(grade_query)

    return grade_query


@router.get("/{query_id}", response_model=GradeQueryResponse)
def get_grade_query(
    query_id: int,
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
    """Retrieve a grade query belonging to the authenticated student."""

    grade_query = db.get(GradeQuery, query_id)

    if grade_query is None:
        raise HTTPException(
            status_code=404,
            detail="Grade query not found.",
        )

    if grade_query.student_id != student.student_id:
        raise HTTPException(
            status_code=404,
            detail="Grade query not found.",
        )

    return grade_query


@router.put("/{query_id}", response_model=GradeQueryResponse)
def update_grade_query(
    query_id: int,
    payload: GradeQueryUpdate,
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
    """Update the reason for the authenticated student's grade query."""

    grade_query = db.get(GradeQuery, query_id)

    if grade_query is None:
        raise HTTPException(
            status_code=404,
            detail="Grade query not found.",
        )

    if grade_query.student_id != student.student_id:
        raise HTTPException(
            status_code=404,
            detail="Grade query not found.",
        )

    if grade_query.status != "pending":
        raise HTTPException(
            status_code=409,
            detail="Only pending grade queries can be updated.",
        )

    grade_query.reason = payload.reason

    db.commit()
    db.refresh(grade_query)

    return grade_query


@router.delete("/{query_id}")
def delete_grade_query(
    query_id: int,
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
    """Delete a pending grade query belonging to the authenticated student."""

    grade_query = db.get(GradeQuery, query_id)

    if grade_query is None:
        raise HTTPException(
            status_code=404,
            detail="Grade query not found.",
        )

    if grade_query.student_id != student.student_id:
        raise HTTPException(
            status_code=404,
            detail="Grade query not found.",
        )

    if grade_query.status != "pending":
        raise HTTPException(
            status_code=409,
            detail="Only pending grade queries can be deleted.",
        )

    db.delete(grade_query)
    db.commit()

    return {
        "message": "Grade query deleted successfully.",
        "query_id": query_id,
    }
