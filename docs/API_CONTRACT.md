# API Contract — agreed between frontend and backend

This is the contract every backend router and every frontend model/service
should match exactly. If a change is needed, raise it in the group chat
first — both sides depend on this shape staying stable.

## Logging in and access

Every student endpoint needs the student's login token in the header:
`Authorization: Bearer <token>` (missing or expired token → **401**).
A `{student_id}` in the URL must be the logged-in student's own id
(someone else's → **403**). Only the two login endpoints are open.

```
POST /auth/login
  send: { "student_number": "EDUV4772514", "password": "..." }
  get:  { "token": "eyJ...", "student_id": 1, "full_name": "Annuschka Deysel" }
  401:  { "detail": "Invalid student number or password" }
```

## Student endpoints (need a student token)

```
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
            "client_updated_at": "2026-10-05T14:30:00Z" } ]
  get:  { "status": "synced", "conflicts": [] }
  Each change is applied to the logged-in student's own submission
  (the student comes from the token, so no student_id in the body).
  A conflict looks like:
        { "table": "assignments", "id": 1, "resolution": "server_wins",
          "server_status": "not_submitted",
          "server_updated_at": "2026-10-05T14:31:00+00:00" }

GET /sync/pull/{student_id}   (changes come down)
  get:  { "assignments": [...], "grades": [...], "timetable": [...],
          "announcements": [...] }  – same shapes as the endpoints above
```

All timestamps sent by the app are UTC with a `Z` (or `+00:00`), so the
"newer update wins" comparison is not thrown off by South African time
(UTC+2).

Conflict rule (applies inside `/sync/push`, per D3 FR12 / US03 / US06):
**the more recent update wins.** If the server's version of a record was
updated more recently than the client's offline edit, the server wins
(protects a lecturer's official grade/update from being overwritten by a
stale offline client write) and the conflict is logged rather than silently
dropped. Pushing the same change twice (a retry after a dropped
connection) is ignored. Owner: Ofentse (`sync_service.py`).

## Lecturer endpoints (US08–US10, need a lecturer token)

In the prototype the lecturer "web portal" is FastAPI's `/docs` page:
log in with `POST /lecturer/login`, click **Authorize**, paste the token.
Lecturers can only change records of the courses they teach (else 403).

```
POST   /lecturer/login              send: { "email": "...", "password": "..." }
                                    get:  { "token": "...", "lecturer_id": 1, "full_name": "..." }
GET    /lecturer/grades             list grades (to find grade_id)
PUT    /lecturer/grades/{grade_id}  send: { "mark": 90, "grade_value": "A", "comment": "..." }  (any of these)
GET    /lecturer/submissions        list submissions (to find submission_id)
PUT    /lecturer/submissions/{id}   send: { "status": "not_submitted" | "submitted" }
POST   /lecturer/announcements      send: { "title": "...", "content": "...", "course_id": 1 or null }
PUT    /lecturer/announcements/{id} send: { "title": "...", "content": "..." }  (any of these)
DELETE /lecturer/announcements/{id}
PUT    /lecturer/timetable/{id}     send: { "day_of_week": "Monday", "start_time": "10:00",
                                            "end_time": "11:30", "venue": "Lab C303" }  (any of these)
```

## Backend base URL

Dev: `http://127.0.0.1:8000` on the machine running `uvicorn`. From the
Flutter app on a USB-connected Android phone, reach it via
`adb reverse tcp:8000 tcp:8000` (per the README), then use
`http://127.0.0.1:8000` from the app too — not `10.0.2.2`, that's only for
the Android **emulator**, not a real phone.
