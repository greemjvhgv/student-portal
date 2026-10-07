# Who works where

Matches the branch prefixes in the README. Create your branch off `main`
(`git checkout -b yourname/short-description`), work only inside your own
files below, and open a PR when it's ready. If you need something another
file doesn't have yet (a model field, an endpoint), ping that person rather
than editing their file — or add it and flag it in the PR description.

| Member | D4 part | Your files |
| --- | --- | --- |
| **Ruan** | Backend: project structure + authentication | `backend/app/main.py`, `backend/app/database.py`, `backend/app/routers/auth.py` |
| **Adnan** | Backend: database models (D3 ERD) | everything in `backend/app/models/` |
| **Leo** | Backend: submissions, grades, grade-query endpoints | `backend/app/routers/grades.py`, `backend/app/routers/assignments.py` |
| **Ofentse** | Backend: sync service + conflict resolution | `backend/app/services/sync_service.py`, `backend/app/routers/sync.py` |
| **Charleen** | Frontend: timetable + announcements screens | `lib/screens/dashboard_screen.dart` (timetable + announcements cards live here per the wireframe), plus `lib/models/timetable_entry.dart` / `announcement.dart` if the shape needs changing |
| **Annuschka (you)** | Frontend: wireframe screens, local database, sync client, repo & integration | the rest of `lib/screens/`, `lib/services/`, `lib/models/`, `lib/widgets/`, plus everything in `docs/` and the root config files |

**Not yet assigned — flag this in your group chat:** `backend/app/routers/timetable.py`,
`announcements.py`, and `course_materials.py` have starter stubs but no
owner in the current role list. Whoever ends up closest to that piece
(possibly Leo, since it's the same pattern as grades/assignments) should
claim it.

## What's already scaffolded vs. what you build

Every file below has a docstring at the top saying what it's for and what
it should do — most are **stubs with TODOs**, not working code, so you're
not stepping on anyone's part by starting. The exceptions, built further
already because they're foundational/shared rather than one person's
"part": `backend/app/database.py`, the model field definitions in
`backend/app/models/` (from Adnan's actual D3 ERD — check them against
your own diagram and adjust, this is a starting point not the final word),
and the frontend data models in `lib/models/` (mirroring the agreed API
contract in `docs/API_CONTRACT.md`).
