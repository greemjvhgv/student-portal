import 'dart:convert';

/// One change made offline, waiting in the local `pending_sync` queue
/// (FR5, FR6). Mirrors the backend's SyncOperation model. [status] is
/// pending / failed (retried) / synced / conflict.
class PendingChange {
  final int syncId;
  final String entityType;
  final int entityId;
  final String operationType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final String status;
  final int attempts;

  const PendingChange({
    required this.syncId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    required this.syncedAt,
    required this.status,
    required this.attempts,
  });

  String get label => switch (entityType) {
    'assignments' => 'Assignment: ${payload['title'] ?? entityId}',
    'grade_queries' => 'Grade query - ${payload['module_code'] ?? ''}',
    _ => '$entityType #$entityId',
  };

  factory PendingChange.fromRow(Map<String, Object?> row) => PendingChange(
    syncId: row['sync_id'] as int,
    entityType: row['entity_type'] as String,
    entityId: row['entity_id'] as int,
    operationType: row['operation_type'] as String,
    payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
    createdAt: DateTime.parse(row['created_at'] as String),
    syncedAt: row['synced_at'] == null
        ? null
        : DateTime.parse(row['synced_at'] as String),
    status: row['status'] as String,
    attempts: row['attempts'] as int,
  );
}
