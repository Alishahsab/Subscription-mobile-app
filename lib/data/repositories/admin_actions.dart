import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/code_rules.dart';
import '../../core/utils/ids.dart';
import '../models/db_row.dart';
import '../models/message.dart';
import '../models/order.dart';
import '../models/ticket.dart';
import '../sync/app_data.dart';
import '../sync/app_lookups.dart';
import '../sync/data_notifier.dart';
import '../sync/db_table.dart';
import '../sync/sync_service.dart';
import 'image_repository.dart';

const adminCancelReason = 'Cancelled by admin';

final adminActionsProvider = Provider((ref) => AdminActions(ref));

bool canDeleteMessage(Message message) {
  return message.sender == 'admin' && (message.kind == 'text' || message.kind == 'image');
}

class SentCode {
  const SentCode(this.code, this.customerEmail, this.sentAt);

  final String code;
  final String customerEmail;
  final int sentAt;
}

SentCode? findCodeAlreadySent(AppData data, String text) {
  final codes = lowerCaseCodesIn(text);
  if (codes.isEmpty) return null;

  for (final order in data.orders) {
    final code = order.code;
    if (code != null && codes.contains(code.toLowerCase())) {
      return SentCode(code, data.customer(order.customerId)?.email ?? 'Customer', order.reviewedAt ?? order.createdAt);
    }
  }

  for (final message in data.messages) {
    if (message.sender != 'admin' || message.kind == 'deleted') continue;
    final repeated = lowerCaseCodesIn(message.text).where(codes.contains).firstOrNull;
    if (repeated != null) {
      return SentCode(repeated.toUpperCase(), data.customer(message.customerId)?.email ?? 'Customer', message.createdAt);
    }
  }
  return null;
}

DbRow stageAfterReply(AppData data, String customerId, {required bool containsCode, required bool ticketReply}) {
  final stage = data.conversations[customerId]?.stage;
  final hasOpenTicket = data.tickets.any((item) => item.customerId == customerId && item.kind == 'support' && item.status == 'open');
  final pendingOrder = data.ordersOf(customerId).where((order) => order.status == 'pending_review').firstOrNull;

  if (containsCode) return {'unread_by_admin': 0, 'stage': 'code_delivered'};
  if (ticketReply && hasOpenTicket) return {'unread_by_admin': 0, 'stage': 'agent_replied'};
  if (hasOpenTicket) return {'unread_by_admin': 0, if (stage != 'agent_replied') 'stage': 'waiting_agent'};
  if (pendingOrder != null) return {'unread_by_admin': 0, 'active_order_id': pendingOrder.id, 'stage': 'awaiting_payment'};
  if (stage != 'awaiting_payment' && stage != 'rejected') return {'unread_by_admin': 0, 'stage': 'live'};
  return {'unread_by_admin': 0};
}

class AdminActions {
  AdminActions(this._ref);

  final Ref _ref;

  AppData get _data => _ref.read(dataProvider);

  SyncService get _sync => _ref.read(syncProvider);

  int get _now => _ref.read(clockProvider).now;

  Future<String> approveOrder(String orderId, String message, String code) async {
    final result = await Supabase.instance.client.rpc<String>(
      'admin_approve_order',
      params: {'order_id': orderId, 'code_message': message, 'code': code},
    );
    unawaited(_sync.catchUp());
    return result;
  }

  void rejectOrder(Order order, String reason) {
    _closeConversation(order, 'rejected');
    _sync.update(DbTable.orders, order.id, {'status': 'rejected', 'reject_reason': reason, 'reviewed_at': _now});

    final text = _data.config!.rejectionMessage.replaceAll('{order_id}', order.id).replaceAll('{reason}', reason);
    _addMessage(order.customerId, 'bot', text);
    _markNotificationsRead(order.customerId);
  }

  void cancelOrder(Order order) {
    if (order.status != 'pending_review' && order.status != 'rejected') return;

    _closeConversation(order, 'menu');
    _sync.update(DbTable.orders, order.id, {'status': 'cancelled', 'reject_reason': adminCancelReason, 'reviewed_at': _now});

    final template = _data.config!.botMessage('orderCancelledByAdmin', 'Your order {order_id} has been cancelled by our team. You can create a new order from the main menu.');
    _addMessage(order.customerId, 'bot', template.replaceAll('{order_id}', order.id));
    _markNotificationsRead(order.customerId);
  }

  void setCodeUnused(Order order, bool unused) {
    _sync.update(DbTable.orders, order.id, {'code_unused': unused});
  }

  void resolveTicket(Ticket ticket) {
    final conversation = _data.conversations[ticket.customerId];
    final payment = ticket.kind == 'payment';
    final closing = payment ? ['waiting_agent'] : ['waiting_agent', 'agent_replied', 'live'];

    if (payment) _sync.update(DbTable.customers, ticket.customerId, {'payment_blocked_until': null});
    if (conversation != null) {
      _sync.update(DbTable.conversations, ticket.customerId, {
        if (closing.contains(conversation.stage)) 'stage': 'menu',
        'last_message_at': _now,
      });
    }
    _sync.update(DbTable.tickets, ticket.id, {'status': 'resolved'});
    if (conversation == null) return;

    final template = payment
        ? _data.config!.botMessage('paymentIssueResolved', 'Your payment issue is resolved. You can place a new order now.')
        : _data.config!.botMessage('issueResolvedByAdmin', 'Your request {ticket_id} has been marked as resolved. If you need anything else, choose Customer Support from the menu.');
    _addMessage(ticket.customerId, 'bot', template.replaceAll('{ticket_id}', ticket.id));
  }

  void sendMessage(String customerId, String text, {bool ticketReply = false}) {
    final found = codeOnOwnLine(text);
    final code = found.isNotEmpty ? found : codesWithDigit(text).firstOrNull;
    final containsCode = code != null;

    _sync.update(DbTable.conversations, customerId, {
      ...stageAfterReply(_data, customerId, containsCode: containsCode, ticketReply: ticketReply),
      'last_message_at': _now,
    });

    final order = containsCode ? _orderAwaitingCode(customerId) : null;
    if (order != null) _sync.update(DbTable.orders, order.id, {'code': code});
    _addMessage(customerId, 'admin', text);
  }

  void sendImage(String customerId, String path, {bool ticketReply = false}) {
    _sync.update(DbTable.conversations, customerId, {
      ...stageAfterReply(_data, customerId, containsCode: false, ticketReply: ticketReply),
      'last_message_at': _now,
    });
    _addMessage(customerId, 'admin', 'Image', kind: 'image', image: path);
  }

  void deleteMessage(Message message) {
    if (!canDeleteMessage(message)) return;
    _sync.update(DbTable.messages, message.id, {'kind': 'deleted', 'text': '', 'image': null});

    final image = message.image;
    if (image != null) _ref.read(imageRepositoryProvider).remove(image);
  }

  void markConversationRead(String customerId) {
    final unread = _data.conversations[customerId]?.unreadByAdmin ?? 0;
    if (unread > 0) _sync.update(DbTable.conversations, customerId, {'unread_by_admin': 0});
    _markNotificationsRead(customerId);
  }

  void blockCustomer(String customerId, String reason) {
    _sync.update(DbTable.customers, customerId, {'blocked': true, 'block_reason': reason});
    _addMessage(customerId, 'admin', '${_data.config!.blockMessage}\nReason: $reason');
  }

  void unblockCustomer(String customerId) {
    _sync.update(DbTable.customers, customerId, {'blocked': false, 'block_reason': null});
    _addMessage(customerId, 'admin', _data.config!.unblockMessage);
  }

  void _closeConversation(Order order, String stage) {
    final conversation = _data.conversations[order.customerId];
    if (conversation == null) return;
    _sync.update(DbTable.conversations, order.customerId, {
      if (conversation.activeOrderId == order.id) 'active_order_id': null,
      'stage': stage,
      'unread_by_admin': 0,
      'last_message_at': _now,
    });
  }

  Order? _orderAwaitingCode(String customerId) {
    final completed = _data.ordersOf(customerId).where((order) => order.status == 'completed').toList()
      ..sort((a, b) => (b.reviewedAt ?? 0).compareTo(a.reviewedAt ?? 0));
    return completed.where((order) => order.code == null).firstOrNull ?? completed.firstOrNull;
  }

  void _addMessage(String customerId, String sender, String text, {String kind = 'text', String? image}) {
    final message = Message(id: createId(), customerId: customerId, sender: sender, kind: kind, text: text, createdAt: _now, image: image);
    _sync.insert(DbTable.messages, message.toRow());
  }

  void _markNotificationsRead(String customerId) {
    for (final notification in _data.notifications) {
      if (notification.customerId == customerId && !notification.read) {
        _sync.update(DbTable.notifications, notification.id, {'read': true});
      }
    }
  }
}
