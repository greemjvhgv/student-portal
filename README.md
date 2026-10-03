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

## Folders
- `lib/` – Flutter app
- `backend/` – FastAPI backend
- `docs/API_CONTRACT.md` – the agreed API between the app and the backend

## You need
- Flutter 3.47.x with Dart 3.13.4 or newer (`flutter --version`; run `flutter upgrade` if older)
- An Android phone with USB debugging on
- Python 3.12 for the backend

## Run the app
1. `flutter pub get`
2. Plug in your phone, then `flutter run`

## Run the backend
Ruan will add the commands here.

## Connect your phone to the backend
With the phone plugged in and the backend running, run `adb reverse tcp:8000 tcp:8000`. Repeat it every time you re-plug the phone. The app then reaches the backend at `http://127.0.0.1:8000`.

## How we work
1. `git checkout main`, then `git pull`
2. `git checkout -b yourname/short-description`
3. Commit small steps; push with `git push -u origin yourname/short-description`
4. Open a Pull Request into `main`; another member reviews and runs it before merging
5. To bring the latest main into your branch: `git checkout main`, `git pull`, `git checkout yourname/short-description`, `git merge main`
6. Never commit `.venv/`, database files, passwords or secret keys