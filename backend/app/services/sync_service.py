"""
Owner: Ofentse (backend: sync service + conflict resolution).

The Sync Service Broker from the D3 Architecture Design. TODO:
  - apply_push(): for each item POST /sync/push receives, log it to
    SyncOperation, compare client_updated_at against
    SyncMetadata.last_modified_at for that record, and write a Conflict
    row (server wins) if the server's version is newer — per FR12/US03/US06
  - pull_changes_since(): return everything changed on the server since
    the student's last sync (grades, assignments, timetable, announcements)
"""


def apply_push(db, table_name: str, record_id: int, fields: dict, client_updated_at):
    raise NotImplementedError("TODO (Ofentse): implement the conflict rule per docs/API_CONTRACT.md")


def pull_changes_since(db, student_id: int):
    raise NotImplementedError("TODO (Ofentse): implement per docs/API_CONTRACT.md")
