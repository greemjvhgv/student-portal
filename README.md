# Offline-First Student Portal – ITMDA3-34 Group 10

A Flutter app for students affected by load shedding and unstable connectivity. Academic data is cached in a local SQLite database (sqflite) so the app keeps working offline. Changes made offline are queued and synchronised with a FastAPI backend when the connection returns (delta sync with timestamp-based conflict rules: the lecturer's more recent update wins).

## Team – Deliverable 4
| Member | Part | Branch prefix |
|---|---|---|
| Annuschka | Frontend: wireframe screens, local database, sync client, repo & integration | `annuschka/` |
| Charleen | Frontend: timetable and announcements screens | `charleen/` |
| Ruan | Backend: project structure and authentication | `ruan/` |
| Adnan | Backend: database models (D3 ERD) | `adnan/` |
| Leo | Backend: submissions, grades and grade-query endpoints | `leo/` |
| Ofentse | Backend: sync service and conflict resolution | `ofentse/` |

**→ See `docs/folder-ownership.md` for exactly which files are yours.**

## Folders
```
student_portal/
├── lib/
│   ├── main.dart          app entry point + routes
│   ├── models/            Dart data classes mirroring the API contract
│   ├── screens/           one file per screen (wireframes D3 Fig 2–8)
│   ├── services/          local database (sqflite), login, connectivity, API client, sync
│   ├── utils/             time formatting
│   └── widgets/           shared UI (app bar, dashed border)
├── backend/
│   ├── app/
│   │   ├── main.py        FastAPI entry point: routers + access rules
│   │   ├── database.py    server-side SQLite setup
│   │   ├── seed.py        demo data (6 students, 1 lecturer, courses, …)
│   │   ├── api/           login checks for students (deps.py, access.py)
│   │   ├── core/          settings, password hashing, tokens
│   │   ├── models/        SQLAlchemy models matching the D3 ERD
│   │   ├── routers/       one file per resource (student, lecturer, sync)
│   │   ├── schemas/       request/response shapes
│   │   └── services/      sync_service.py — the Sync Service Broker
│   └── tests/             backend tests (pytest)
└── docs/
    ├── API_CONTRACT.md       the agreed API between the app and the backend
    └── folder-ownership.md   who works in which file
```

## You need
- Flutter 3.47.x with Dart 3.13.4 or newer (`flutter --version`; run `flutter upgrade` if older)
- An Android phone with USB debugging on
- Python 3.12 for the backend (not 3.14)
- Windows: Developer Mode on (Settings → System → For developers)

## Set up the backend (once)
From the `backend` folder:
```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m app.seed
```
The seed creates a login for every group member (their student number,
password `Test@123`) and a lecturer (`lecturer@test.local`, password
`Test@123`). To start again with fresh data: stop the backend, delete
`backend\student_portal.db` and run the seed again.

## Run the backend
From the `backend` folder (leave the window open):
```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```
Runs at `http://127.0.0.1:8000`; interactive docs at `/docs`.
Run the tests with `.\.venv\Scripts\python.exe -m pytest`.

## Run the app on your phone
From the project folder, with the backend running and the phone plugged in:
```powershell
& "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
flutter run
```
Repeat the `adb reverse` line every time you re-plug the phone. Log in with
your student number and `Test@123`.

## Demo: offline submission and a conflict
1. In the app: airplane mode **on** → Assignments → submit an assignment → it shows "Queued offline" and is listed in Sync Status.
2. In `/docs` as the lecturer: `POST /lecturer/login`, click **Authorize** and paste the token, `GET /lecturer/submissions` to find that submission, then `PUT /lecturer/submissions/{id}` with `{"status": "not_submitted"}`.
3. In the app: airplane mode **off** → the app syncs by itself → open Sync Status and tap **Sync Now** → the "Conflict Resolved" pop-up shows the lecturer's newer change won.
4. Without step 2 the submission simply syncs and shows as "Submitted".

## How we work
1. `git checkout main`, then `git pull`
2. `git checkout -b yourname/short-description`
3. Commit small steps; push with `git push -u origin yourname/short-description`
4. Open a Pull Request into `main`; another member reviews and runs it before merging
5. To bring the latest main into your branch: `git checkout main`, `git pull`, `git checkout yourname/short-description`, `git merge main`
6. Never commit `.venv/`, database files, passwords or secret keys
7. Changing the API contract? Edit `docs/API_CONTRACT.md` first and flag it in the group chat — both frontend and backend build against that file
