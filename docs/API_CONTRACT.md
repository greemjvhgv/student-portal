# API Contract — agreed between frontend and backend

This is the contract every backend router and every frontend model/service
should match exactly. If a change is needed, raise it in the group chat
first — both sides depend on this shape staying stable.

```
POST /auth/login
  send: { "student_number": "12345678", "password": "..." }
  get:  { "token": "abc123", "student_id": 1, "full_name": "John Doe" }

GET /timetable/{student_id}
  get:  [ { "module_code": "ITMDA3-34", "day": "Monday", "time": "09:00", "type": "Lecture" } ]

GET /announcements
  get:  [ { "title": "Portal maintenance", "body": "Sat 10pm", "posted_at": "2026-09-28" } ]

GET /grades/{student_id}
  get:  [ { "module_code": "ITMDA3-34", "mark": 78, "updated_at": "2026-09-28" } ]

GET /assignments/{student_id}
  get:  [ { "id": 1, "module_code": "ITMDA3-34", "title": "Deliverable 4",
            "status": "not_submitted", "due_date": "2026-10-22" } ]

POST /assignments/{id}/submit
  get:  { "status": "submitted", "assignment_id": 1 }

GET /course-materials/{module_code}
  get:  [ { "title": "Week 5 Study Guide", "file_url": "..." } ]

POST /sync/push        (offline changes go up)
  send: [ { "table": "assignments", "id": 1, "status": "submitted",
            "client_updated_at": "2026-10-05T14:30:00" } ]
  get:  { "status": "synced", "conflicts": [] }

GET /sync/pull/{student_id}   (changes come down)
  get:  everything changed on the server since your last sync —
        same shape as the grades/assignments/timetable responses above
```

Conflict rule (applies inside `/sync/push`, per D3 FR12 / US03 / US06):
**the more recent update wins.** If the server's version of a record was
updated more recently than the client's offline edit, the server wins
(protects a lecturer's official grade/update from being overwritten by a
stale offline client write) and the conflict is logged rather than silently
dropped. Owner: Ofentse (`sync_service.py`).

## Backend base URL

Dev: `http://127.0.0.1:8000` on the machine running `uvicorn`. From the
Flutter app on a USB-connected Android phone, reach it via
`adb reverse tcp:8000 tcp:8000` (per the README), then use
`http://127.0.0.1:8000` from the app too — not `10.0.2.2`, that's only for
the Android **emulator**, not a real phone.
