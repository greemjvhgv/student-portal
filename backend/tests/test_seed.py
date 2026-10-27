"""
Owner: Annuschka (D5 bug fix: deadlines shown at 01:59).

The seed's deadlines must read 23:59 in South Africa once the app converts
the server's UTC time to local time.
"""
from datetime import date, datetime, timezone

from app.seed import SAST, due_at


def test_due_at_is_stored_in_utc():
    assert due_at(date(2026, 10, 30)) == datetime(2026, 10, 30, 21, 59)


def test_due_at_reads_2359_in_south_africa():
    stored = due_at(date(2026, 10, 30))
    local = stored.replace(tzinfo=timezone.utc).astimezone(SAST)
    assert (local.date(), local.strftime("%H:%M")) == (date(2026, 10, 30), "23:59")
