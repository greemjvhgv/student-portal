# Who works where

Matches the branch prefixes in the README. Create your branch off `main`
(`git checkout -b yourname/short-description`), work only inside your own
files below, and open a PR when it's ready. If you need something another
file doesn't have yet (a model field, an endpoint), ping that person rather
than editing their file — or add it and flag it in the PR description.

| Member | D4 part | Files |
| --- | --- | --- |
| **Ruan** | Backend: project structure + authentication | `backend/app/main.py`, `backend/app/database.py`, `backend/app/routers/auth.py`, `backend/app/api/deps.py`, `backend/app/core/`, `backend/app/schemas/auth.py`, `backend/tests/test_auth.py`, `lib/services/auth_service.dart` |
| **Adnan** | Backend: database models (D3 ERD) + demo data | everything in `backend/app/models/`, `backend/app/seed.py` |
| **Leo** | Backend: student endpoints + submissions / grade-query CRUD | `backend/app/routers/grades.py`, `assignments.py`, `timetable.py`, `announcements.py`, `course_materials.py`, `grade_queries.py`, `backend/app/services/submission_*.py` |
| **Ofentse** | Backend: sync service + conflict resolution | `backend/app/services/sync_service.py`, `backend/app/routers/sync.py` |
| **Charleen** | Frontend: timetable + announcements screens | `lib/screens/dashboard_screen.dart`, `timetable_screen.dart`, `announcements_screen.dart`, `announcement_detail_screen.dart` |
| **Annuschka** | Frontend: wireframe screens, local database, sync client, repo & integration | the rest of `lib/`, `backend/app/routers/lecturer.py`, `backend/app/api/access.py`, `backend/tests/test_access_lecturer_sync.py`, everything in `docs/` and the root config files |

New routers must be registered in `backend/app/main.py`. Student routers
are added with `dependencies=_student_only`, so they automatically require
a student login and only allow a student's own `{student_id}`.
