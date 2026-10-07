"""
Owner: Ruan (backend project structure + authentication).

App entry point. TODO once each router below actually exists (right now
they're stubs that raise NotImplementedError when called, but they DO
import cleanly, so this file runs as-is):
  - confirm CORS settings are right for the Flutter app's requests
  - decide whether to keep Base.metadata.create_all() for dev, or move to
    a real migration tool before this goes further
"""
from fastapi import FastAPI
from app.database import Base, engine
from app.routers import auth, timetable, announcements, grades, assignments, course_materials, sync

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Group 10 — Offline-First Student Portal API",
    description="Backend REST API for the ITMDA3-34 Deliverable 4 prototype.",
    version="0.1.0",
)


@app.get("/")
def root():
    return {"status": "ok", "service": "student-portal-api"}


app.include_router(auth.router)
app.include_router(timetable.router)
app.include_router(announcements.router)
app.include_router(grades.router)
app.include_router(assignments.router)
app.include_router(course_materials.router)
app.include_router(sync.router)
