"""
Dev seed: creates a student role and a test student.
Run from backend/:  python seed.py
Login with EDUV1234567 / password123
"""
from app.core.security import hash_password
from app.database import Base, SessionLocal, engine
from app.models import Role, Student, User


def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        role = db.query(Role).filter_by(role_name="student").first()
        if not role:
            role = Role(role_name="student")
            db.add(role)
            db.flush()
        if not db.query(Student).filter_by(student_number="EDUV1234567").first():
            user = User(
                email="john.doe@student.eduvos.com",
                password_hash=hash_password("password123"),
                role_id=role.role_id,
            )
            db.add(user)
            db.flush()
            db.add(Student(user_id=user.user_id, student_number="EDUV1234567",
                           first_name="John", last_name="Doe"))
        db.commit()
        print("Seeded. Login: EDUV1234567 / password123")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
