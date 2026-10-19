"""
Owner: Ruan (backend project structure + authentication).

App entry point: creates the database tables, enables CORS for local
development and registers the routers.

Access rules:
  - /auth/login and /lecturer/login are open.
  - Every student router requires a student login token, and a
    {student_id} in the URL must be the student's own id
    (app/api/access.py).
  - /lecturer/* routes require a lecturer token (app/routers/lecturer.py).
"""
from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.access import require_student_access
from app.database import Base, engine
from app.routers import (
    announcements,
    assignments,
    auth,
    course_materials,
    grade_queries,
    grades,
    lecturer,
    sync,
    timetable,
)

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Group 10 — Offline-First Student Portal API",
    description="Backend REST API for the ITMDA3-34 Deliverable 4 prototype.",
    version="0.1.0",
)


# Needed when the Flutter app runs in a browser (flutter run -d chrome); the
# web app is served from a random localhost port. Native/mobile ignores CORS.
# Bearer tokens are sent in a header, not cookies, so credentials stay off.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    return {"status": "ok", "service": "student-portal-api"}


# Open: logging in.
app.include_router(auth.router)
app.include_router(lecturer.router)

# Students only, and only their own data.
_student_only = [Depends(require_student_access)]
app.include_router(timetable.router, dependencies=_student_only)
app.include_router(announcements.router, dependencies=_student_only)
app.include_router(grades.router, dependencies=_student_only)
app.include_router(assignments.router, dependencies=_student_only)
app.include_router(course_materials.router, dependencies=_student_only)
app.include_router(sync.router, dependencies=_student_only)
app.include_router(grade_queries.router, dependencies=_student_only)
