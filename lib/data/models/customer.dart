import 'db_row.dart';

class Customer {
  const Customer({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.lastSeenAt,
    required this.blocked,
    required this.cancelCount,
    this.number,
    this.blockReason,
    this.blockedAt,
    this.paymentBlockedUntil,
    this.cancelCooldownUntil,
    this.whatsapp,
  });

  final String id;
  final int? number;
  final String email;
  final int createdAt;
  final int lastSeenAt;
  final bool blocked;
  final String? blockReason;
  final int? blockedAt;
  final int? paymentBlockedUntil;
  final int cancelCount;
  final int? cancelCooldownUntil;
  final String? whatsapp;

  factory Customer.fromRow(DbRow row) {
    return Customer(
      id: row['id'] as String,
      number: asIntOrNull(row['customer_number']),
      email: row['email'] as String,
      createdAt: asInt(row['created_at']),
      lastSeenAt: asInt(row['last_seen_at']),
      blocked: row['blocked'] as bool,
      blockReason: row['block_reason'] as String?,
      blockedAt: asIntOrNull(row['blocked_at']),
      paymentBlockedUntil: asIntOrNull(row['payment_blocked_until']),
      cancelCount: asInt(row['cancel_count'] ?? 0),
      cancelCooldownUntil: asIntOrNull(row['cancel_cooldown_until']),
      whatsapp: row['whatsapp'] as String?,
    );
  }

  DbRow toRow() {
    return {
      'id': id,
      'customer_number': number,
      'email': email,
      'created_at': createdAt,
      'last_seen_at': lastSeenAt,
      'blocked': blocked,
      'block_reason': blockReason,
      'blocked_at': blockedAt,
      'payment_blocked_until': paymentBlockedUntil,
      'cancel_count': cancelCount,
      'cancel_cooldown_until': cancelCooldownUntil,
      'whatsapp': whatsapp,
    };
  }
}
