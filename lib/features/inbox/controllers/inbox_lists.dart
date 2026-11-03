import 'dart:math';

import '../../../core/utils/format.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/message.dart';
import '../../../data/models/order.dart';
import '../../../data/sync/app_data.dart';
import '../../../data/sync/app_lookups.dart';
import '../models/inbox_item.dart';

class BotFilter {
  BotFilter._();

  static const activeChats = 'active_chats';
  static const activeOrders = 'active_orders';
  static const cancelled = 'cancelled';
  static const inactiveChats = 'inactive_chats';
}

bool canStillPay(Order order, int now) => order.status == 'awaiting_payment' && order.expiresAt > now;

bool isPending(Order order) => order.status == 'pending_review' || order.status == 'rejected';

String customerTitle(Customer customer) {
  final whatsapp = customer.whatsapp;
  return whatsapp == null || whatsapp.isEmpty ? customer.email : whatsapp;
}

String customerTag(Customer? customer) => customer?.number == null ? 'New' : '#${customer!.number}';

int lastActivityAt(AppData data, String customerId) {
  return max(data.customer(customerId)?.lastSeenAt ?? 0, data.lastCustomerMessageAt(customerId));
}

bool isCustomerActive(AppData data, String customerId, int now) {
  if (data.customers.any((customer) => customer.id == customerId && customer.blocked)) return false;
  final minutes = data.config?.inactiveMinutes ?? 20;
  return now - lastActivityAt(data, customerId) < minutes * Duration.millisecondsPerMinute;
}

String _waitLabel(int time, int now) => timeAgo(time, now).replaceAll(' ago', '');

String _titleOf(AppData data, String customerId) {
  final customer = data.customer(customerId);
  return customer == null ? 'Customer' : customerTitle(customer);
}

InboxItem _orderItem(AppData data, Order order, int time, String subtitle, {String? badge, BadgeTone tone = BadgeTone.gray, bool unread = false}) {
  return InboxItem(
    key: order.id,
    customerId: order.customerId,
    title: _titleOf(data, order.customerId),
    tag: customerTag(data.customer(order.customerId)),
    subtitle: subtitle,
    time: time,
    unread: unread,
    badge: badge,
    badgeTone: tone,
  );
}

List<InboxItem> pendingItems(AppData data, int now) {
  int submittedAt(Order order) => order.submittedAt ?? order.createdAt;
  final orders = data.orders.where(isPending).toList()..sort((a, b) => submittedAt(b).compareTo(submittedAt(a)));

  return orders.map((order) {
    final rejected = order.status == 'rejected';
    return _orderItem(
      data,
      order,
      submittedAt(order),
      '${order.planName} · ${formatMoney(order.amount)} · ${order.methodName}',
      badge: rejected ? 'Rejected, awaiting reply' : 'waiting ${_waitLabel(submittedAt(order), now)}',
      tone: rejected ? BadgeTone.red : BadgeTone.amber,
      unread: !rejected,
    );
  }).toList();
}

List<InboxItem> issueItems(AppData data) {
  final tickets = data.tickets.where((item) => item.status == 'open' && item.kind == 'support').toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return tickets.map((ticket) {
    return InboxItem(
      key: ticket.id,
      customerId: ticket.customerId,
      title: _titleOf(data, ticket.customerId),
      tag: customerTag(data.customer(ticket.customerId)),
      subtitle: ticket.message,
      time: ticket.createdAt,
      unread: true,
      badge: 'Open · ${ticket.id}',
      badgeTone: BadgeTone.red,
    );
  }).toList();
}

List<InboxItem> completedItems(AppData data, {required bool unused}) {
  final orders = data.orders.where((order) => order.status == 'completed' && order.codeUnused == unused).toList()
    ..sort((a, b) => (b.reviewedAt ?? 0).compareTo(a.reviewedAt ?? 0));

  return orders.map((order) {
    final subtitle = order.code == null ? '${order.planName} · code not sent yet' : '${order.planName} · ${order.code}';
    return _orderItem(data, order, order.reviewedAt ?? order.createdAt, subtitle);
  }).toList();
}

List<InboxItem> blockedItems(AppData data) {
  int blockedAt(Customer customer) => customer.blockedAt ?? customer.lastSeenAt;
  final customers = data.customers.where((item) => item.blocked).toList()..sort((a, b) => blockedAt(b).compareTo(blockedAt(a)));

  return customers.map((customer) {
    return InboxItem(
      key: customer.id,
      customerId: customer.id,
      title: customerTitle(customer),
      tag: customerTag(customer),
      subtitle: customer.blockReason ?? 'No reason given',
      time: blockedAt(customer),
      badge: 'Blocked',
      badgeTone: BadgeTone.red,
    );
  }).toList();
}

List<InboxItem> inboxItems(AppData data, String tab, int now) {
  switch (tab) {
    case 'pending':
      return pendingItems(data, now);
    case 'issues':
      return issueItems(data);
    case 'completed':
      return completedItems(data, unused: false);
    case 'unused':
      return completedItems(data, unused: true);
    default:
      return blockedItems(data);
  }
}

Map<String, int> countInboxTabs(AppData data) {
  return {
    'pending': data.orders.where(isPending).length,
    'issues': data.tickets.where((item) => item.status == 'open' && item.kind == 'support').length,
    'completed': 0,
    'unused': data.orders.where((order) => order.status == 'completed' && order.codeUnused).length,
    'blocked': data.customers.where((item) => item.blocked).length,
  };
}

String describeMessage(Message message) {
  switch (message.kind) {
    case 'payment':
      return 'Order created';
    case 'proof':
      return 'Payment proof submitted';
    case 'steps':
      return 'Payment steps shown';
    case 'image':
      return 'Screenshot';
    case 'code':
      return 'Code sent';
    case 'deleted':
      return 'Message deleted';
    default:
      return message.text;
  }
}

const _chatKept = Duration(days: 15);

bool _hasChat(AppData data, Conversation conversation, int now) {
  return data.messagesOf(conversation.customerId).isNotEmpty || now - conversation.lastMessageAt < _chatKept.inMilliseconds;
}

List<InboxItem> chatItems(AppData data, {required bool active, required int now}) {
  final conversations = data.conversations.values
      .where((item) => _hasChat(data, item, now))
      .where((item) => isCustomerActive(data, item.customerId, now) == active)
      .toList()
    ..sort((a, b) => lastActivityAt(data, b.customerId).compareTo(lastActivityAt(data, a.customerId)));

  return conversations.map((conversation) {
    final customerId = conversation.customerId;
    final activeAt = lastActivityAt(data, customerId);
    final lastMessage = data.messagesOf(customerId).lastOrNull;
    final prefix = lastMessage == null || lastMessage.sender == 'customer' ? '' : 'You: ';

    return InboxItem(
      key: customerId,
      customerId: customerId,
      title: _titleOf(data, customerId),
      tag: customerTag(data.customer(customerId)),
      subtitle: lastMessage == null ? '' : prefix + describeMessage(lastMessage),
      time: activeAt,
      unread: conversation.unreadByAdmin > 0,
      badge: active ? null : 'Inactive · ${_waitLabel(activeAt, now)}',
    );
  }).toList();
}

List<InboxItem> activeOrderItems(AppData data, int now) {
  final orders = data.orders.where((order) => canStillPay(order, now)).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return orders.map((order) {
    final minutesLeft = ((order.expiresAt - now) / Duration.millisecondsPerMinute).ceil();
    return _orderItem(
      data,
      order,
      order.createdAt,
      '${order.planName} · ${formatMoney(order.amount)} · ${order.methodName}',
      badge: '$minutesLeft min left to pay',
      tone: BadgeTone.blue,
    );
  }).toList();
}

int _cancelledAt(Order order) => order.status == 'expired' ? order.expiresAt : (order.reviewedAt ?? order.createdAt);

List<InboxItem> cancelledItems(AppData data, int now) {
  final orders = data.orders.where((order) => order.status == 'cancelled' || order.status == 'expired').toList()
    ..sort((a, b) => _cancelledAt(b).compareTo(_cancelledAt(a)));

  return orders.map((order) {
    final label = order.status == 'expired' ? 'Time ran out' : 'Cancelled by customer';
    return _orderItem(
      data,
      order,
      _cancelledAt(order),
      '${order.planName} · ${formatMoney(order.amount)}',
      badge: '$label · ${timeAgo(_cancelledAt(order), now)}',
    );
  }).toList();
}

List<InboxItem> botItems(AppData data, String filter, int now) {
  switch (filter) {
    case BotFilter.activeOrders:
      return activeOrderItems(data, now);
    case BotFilter.cancelled:
      return cancelledItems(data, now);
    case BotFilter.inactiveChats:
      return chatItems(data, active: false, now: now);
    default:
      return chatItems(data, active: true, now: now);
  }
}

bool matchesSearch(AppData data, InboxItem item, String words) {
  final order = data.orders.where((entry) => entry.id == item.key).firstOrNull;
  final text = [item.title, item.tag, item.subtitle, order?.senderName ?? '', order?.code ?? ''].join(' ').toLowerCase();
  return text.contains(words);
}
