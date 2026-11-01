import 'db_row.dart';

class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.methodName,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.codeUnused,
    this.bankName,
    this.accountTitle,
    this.accountNumber,
    this.iban,
    this.paymentSteps,
    this.submittedAt,
    this.reviewedAt,
    this.screenshot,
    this.senderName,
    this.rejectReason,
    this.code,
  });

  final String id;
  final String customerId;
  final String planId;
  final String planName;
  final int amount;
  final String methodName;
  final String? bankName;
  final String? accountTitle;
  final String? accountNumber;
  final String? iban;
  final String? paymentSteps;
  final String status;
  final int createdAt;
  final int expiresAt;
  final int? submittedAt;
  final int? reviewedAt;
  final String? screenshot;
  final String? senderName;
  final String? rejectReason;
  final String? code;
  final bool codeUnused;

  factory Order.fromRow(DbRow row) {
    return Order(
      id: row['id'] as String,
      customerId: row['customer_id'] as String,
      planId: row['plan_id'] as String,
      planName: row['plan_name'] as String,
      amount: asInt(row['amount']),
      methodName: row['method_name'] as String,
      bankName: row['bank_name'] as String?,
      accountTitle: row['account_title'] as String?,
      accountNumber: row['account_number'] as String?,
      iban: row['iban'] as String?,
      paymentSteps: row['payment_steps'] as String?,
      status: row['status'] as String,
      createdAt: asInt(row['created_at']),
      expiresAt: asInt(row['expires_at']),
      submittedAt: asIntOrNull(row['submitted_at']),
      reviewedAt: asIntOrNull(row['reviewed_at']),
      screenshot: row['screenshot'] as String?,
      senderName: row['sender_name'] as String?,
      rejectReason: row['reject_reason'] as String?,
      code: row['code'] as String?,
      codeUnused: row['code_unused'] == true,
    );
  }

  DbRow toRow() {
    return {
      'id': id,
      'customer_id': customerId,
      'plan_id': planId,
      'plan_name': planName,
      'amount': amount,
      'method_name': methodName,
      'bank_name': bankName,
      'account_title': accountTitle,
      'account_number': accountNumber,
      'iban': iban,
      'payment_steps': paymentSteps,
      'status': status,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'submitted_at': submittedAt,
      'reviewed_at': reviewedAt,
      'screenshot': screenshot,
      'sender_name': senderName,
      'reject_reason': rejectReason,
      'code': code,
      'code_unused': codeUnused,
    };
  }
}
