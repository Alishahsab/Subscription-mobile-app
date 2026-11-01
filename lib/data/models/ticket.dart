import 'db_row.dart';

class Ticket {
  const Ticket({
    required this.id,
    required this.customerId,
    required this.kind,
    required this.message,
    required this.status,
    required this.createdAt,
    this.screenshot,
    this.orderId,
  });

  final String id;
  final String customerId;
  final String kind;
  final String message;
  final String? screenshot;
  final String? orderId;
  final String status;
  final int createdAt;

  factory Ticket.fromRow(DbRow row) {
    return Ticket(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      kind: row['kind'] as String,
      message: row['message'] as String,
      screenshot: row['screenshot'] as String?,
      orderId: row['order_id'] as String?,
      status: row['status'] as String,
      createdAt: asInt(row['created_at']),
    );
  }

  DbRow toRow() {
    return {
      'id': id,
      'customer_id': customerId,
      'kind': kind,
      'message': message,
      'screenshot': screenshot,
      'order_id': orderId,
      'status': status,
      'created_at': createdAt,
    };
  }
}
