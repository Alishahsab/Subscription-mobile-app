import 'db_row.dart';

class Conversation {
  const Conversation({
    required this.customerId,
    required this.stage,
    required this.unreadByAdmin,
    required this.lastMessageAt,
    this.planId,
    this.methodId,
    this.activeOrderId,
  });

  final String customerId;
  final String stage;
  final String? planId;
  final String? methodId;
  final String? activeOrderId;
  final int unreadByAdmin;
  final int lastMessageAt;

  factory Conversation.fromRow(DbRow row) {
    return Conversation(
      customerId: row['customer_id'] as String,
      stage: row['stage'] as String,
      planId: row['plan_id'] as String?,
      methodId: row['method_id'] as String?,
      activeOrderId: row['active_order_id'] as String?,
      unreadByAdmin: asInt(row['unread_by_admin']),
      lastMessageAt: asInt(row['last_message_at']),
    );
  }

  DbRow toRow() {
    return {
      'customer_id': customerId,
      'stage': stage,
      'plan_id': planId,
      'method_id': methodId,
      'active_order_id': activeOrderId,
      'unread_by_admin': unreadByAdmin,
      'last_message_at': lastMessageAt,
    };
  }
}
