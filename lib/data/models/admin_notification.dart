import 'db_row.dart';

class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.customerId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final String customerId;
  final bool read;
  final int createdAt;

  factory AdminNotification.fromRow(DbRow row) {
    return AdminNotification(
      id: row['id'] as String,
      kind: row['kind'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      customerId: row['customer_id'] as String,
      read: row['read'] as bool,
      createdAt: asInt(row['created_at']),
    );
  }

  DbRow toRow() {
    return {
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      'customer_id': customerId,
      'read': read,
      'created_at': createdAt,
    };
  }
}
