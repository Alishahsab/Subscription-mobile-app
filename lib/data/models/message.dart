import 'db_row.dart';

class Message {
  const Message({
    required this.id,
    required this.customerId,
    required this.sender,
    required this.kind,
    required this.text,
    required this.createdAt,
    this.orderId,
    this.image,
    this.emailedTo,
    this.deliveredAt,
    this.seenAt,
  });

  final String id;
  final String customerId;
  final String sender;
  final String kind;
  final String text;
  final String? orderId;
  final String? image;
  final String? emailedTo;
  final int createdAt;
  final int? deliveredAt;
  final int? seenAt;

  factory Message.fromRow(DbRow row) {
    return Message(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      sender: row['sender'] as String,
      kind: row['kind'] as String,
      text: row['text'] as String,
      orderId: row['order_id'] as String?,
      image: row['image'] as String?,
      emailedTo: row['emailed_to'] as String?,
      createdAt: asInt(row['created_at']),
      deliveredAt: asIntOrNull(row['delivered_at']),
      seenAt: asIntOrNull(row['seen_at']),
    );
  }

  DbRow toRow() {
    return {
      'id': id,
      'customer_id': customerId,
      'sender': sender,
      'kind': kind,
      'text': text,
      'order_id': orderId,
      'image': image,
      'emailed_to': emailedTo,
      'created_at': createdAt,
      'delivered_at': deliveredAt,
      'seen_at': seenAt,
    };
  }
}
