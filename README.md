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
│   ├── main.dart          app entry point + routes (Annuschka)
│   ├── models/            Dart data classes mirroring the API contract
│   ├── screens/            one file per wireframe screen
│   ├── services/          local_db_service.dart (sqflite) + sync_service.dart (http)
│   └── widgets/           shared UI (offline_badge.dart, etc.)
├── backend/
│   └── app/
│       ├── main.py        FastAPI entry point (Ruan)
│       ├── database.py    server-side DB setup (Ruan)
│       ├── models/        SQLAlchemy models matching the D3 ERD (Adnan)
│       ├── routers/       one file per resource — see docs/folder-ownership.md
│       └── services/      sync_service.py — the Sync Service Broker (Ofentse)
└── docs/
    ├── API_CONTRACT.md       the agreed API between the app and the backend
    └── folder-ownership.md   who works in which file
```

## You need
- Flutter 3.47.x with Dart 3.13.4 or newer (`flutter --version`; run `flutter upgrade` if older)
- An Android phone with USB debugging on
- Python 3.12 for the backend

## Run the app
1. `flutter pub get`
2. Plug in your phone, then `flutter run`

## Run the backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
Runs at `http://127.0.0.1:8000` (interactive docs at `/docs`). Routers are
currently stubs (raise `NotImplementedError`) until each owner fills theirs
in per `docs/folder-ownership.md` — the app will still start and list all
routes, so you can build against it incrementally.

## Connect your phone to the backend
With the phone plugged in and the backend running, run `adb reverse tcp:8000 tcp:8000`. Repeat it every time you re-plug the phone. The app then reaches the backend at `http://127.0.0.1:8000`.

## How we work
1. `git checkout main`, then `git pull`
2. `git checkout -b yourname/short-description`
3. Commit small steps; push with `git push -u origin yourname/short-description`
4. Open a Pull Request into `main`; another member reviews and runs it before merging
5. To bring the latest main into your branch: `git checkout main`, `git pull`, `git checkout yourname/short-description`, `git merge main`
6. Never commit `.venv/`, database files, passwords or secret keys
7. Changing the API contract? Edit `docs/API_CONTRACT.md` first and flag it in the group chat — both frontend and backend build against that file
