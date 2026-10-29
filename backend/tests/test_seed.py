"""
Owner: Annuschka (D5 bug fix: deadlines shown at 01:59).

The seed's deadlines must read 23:59 in South Africa once the app converts
the server's UTC time to local time.

Running the seed again on another day must replace the timetable, not add
a second set of slots (BUG-18).
"""
from datetime import date, datetime, timezone

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session, sessionmaker

import app.seed as seed_module
from app.models import Timetable
from app.seed import SAST, due_at


def test_due_at_is_stored_in_utc():
    assert due_at(date(2026, 10, 30)) == datetime(2026, 10, 30, 21, 59)


def test_due_at_reads_2359_in_south_africa():
    stored = due_at(date(2026, 10, 30))
    local = stored.replace(tzinfo=timezone.utc).astimezone(SAST)
    assert (local.date(), local.strftime("%H:%M")) == (date(2026, 10, 30), "23:59")


def _seed_on(day, monkeypatch):
    class FixedDate(date):
        @classmethod
        def today(cls):
            return day

    monkeypatch.setattr(seed_module, "date", FixedDate)
    seed_module.seed()


def test_reseeding_on_another_day_replaces_the_timetable(tmp_path, monkeypatch):
    engine = create_engine(f"sqlite:///{tmp_path / 'seed.db'}")
    monkeypatch.setattr(seed_module, "engine", engine)
    monkeypatch.setattr(seed_module, "SessionLocal", sessionmaker(bind=engine))

    _seed_on(date(2026, 10, 28), monkeypatch)
    _seed_on(date(2026, 10, 30), monkeypatch)

    with Session(engine) as db:
        days = db.scalars(select(Timetable.day_of_week)).all()
    assert len(days) == 9
    assert set(days) == {"Friday", "Saturday"}
