"""
Owner: Ruan (backend project structure).

Database setup for the backend's OWN server-side store — separate from the
SQLite database that lives on each student's phone via sqflite (that one's
in lib/services/local_db_service.dart). The Sync Service Broker
(app/services/sync_service.py, Ofentse) is what reconciles the two.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# SQLite file for local development; swap for a real Postgres URL in
# production if the group wants to (not required for the prototype).
DATABASE_URL = "sqlite:///./student_portal.db"

engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
