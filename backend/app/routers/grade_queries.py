"""
Owner: Leo (backend: grade-query CRUD endpoints).

Grade queries module (create / read / update / delete), always for the
logged-in student's own queries (wireframe Fig 5 "Flag a grade query"):
  POST   /grade-queries             create a query about one of your grades
  GET    /grade-queries             list your queries
  GET    /grade-queries/{query_id}  read one query
  PUT    /grade-queries/{query_id}  edit the reason (only while pending)
  DELETE /grade-queries/{query_id}  withdraw (only while pending)
Queries made offline in the app arrive through POST /sync/push instead.
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


@router.get("", response_model=list[GradeQueryResponse])
def list_grade_queries(
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
    return (
        db.query(GradeQuery)
        .filter(GradeQuery.student_id == student.student_id)
        .order_by(GradeQuery.query_id.desc())
        .all()
    )


@router.get("/{query_id}", response_model=GradeQueryResponse)
def get_grade_query(
    query_id: int,
    student=Depends(get_current_student),
    db: Session = Depends(get_db),
):
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
