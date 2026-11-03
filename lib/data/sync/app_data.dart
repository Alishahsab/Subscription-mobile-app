import '../models/admin_notification.dart';
import '../models/conversation.dart';
import '../models/customer.dart';
import '../models/message.dart';
import '../models/order.dart';
import '../models/db_row.dart';
import '../models/store_config.dart';
import '../models/ticket.dart';
import 'db_table.dart';


class AppData {
  const AppData({
    this.loaded = false,
    this.config,
    this.customers = const [],
    this.conversations = const {},
    this.orders = const [],
    this.messages = const [],
    this.tickets = const [],
    this.notifications = const [],
  });

  final bool loaded;
  final StoreConfig? config;
  final List<Customer> customers;
  final Map<String, Conversation> conversations;
  final List<Order> orders;
  final List<Message> messages;
  final List<Ticket> tickets;
  final List<AdminNotification> notifications;

  AppData copyWith({
    bool? loaded,
    StoreConfig? config,
    List<Customer>? customers,
    Map<String, Conversation>? conversations,
    List<Order>? orders,
    List<Message>? messages,
    List<Ticket>? tickets,
    List<AdminNotification>? notifications,
  }) {
    return AppData(
      loaded: loaded ?? this.loaded,
      config: config ?? this.config,
      customers: customers ?? this.customers,
      conversations: conversations ?? this.conversations,
      orders: orders ?? this.orders,
      messages: messages ?? this.messages,
      tickets: tickets ?? this.tickets,
      notifications: notifications ?? this.notifications,
    );
  }

  DbRow? rowOf(DbTable table, String id) {
    if (table == DbTable.conversations) return conversations[id]?.toRow();
    for (final row in rowsOf(table)) {
      if (row[table.key] == id) return row;
    }
    return null;
  }

  Iterable<DbRow> rowsOf(DbTable table) {
    if (table == DbTable.customers) return customers.map((item) => item.toRow());
    if (table == DbTable.conversations) return conversations.values.map((item) => item.toRow());
    if (table == DbTable.orders) return orders.map((item) => item.toRow());
    if (table == DbTable.messages) return messages.map((item) => item.toRow());
    if (table == DbTable.tickets) return tickets.map((item) => item.toRow());
    return notifications.map((item) => item.toRow());
  }

  AppData withRow(DbTable table, DbRow row) {
    if (table == DbTable.customers) {
      return copyWith(customers: _upsert(customers, Customer.fromRow(row), (item) => item.id));
    }
    if (table == DbTable.conversations) {
      final conversation = Conversation.fromRow(row);
      return copyWith(conversations: {...conversations, conversation.customerId: conversation});
    }
    if (table == DbTable.orders) {
      return copyWith(orders: _upsert(orders, Order.fromRow(row), (item) => item.id));
    }
    if (table == DbTable.messages) {
      final list = _upsert(messages, Message.fromRow(row), (item) => item.id);
      return copyWith(messages: list..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
    }
    if (table == DbTable.tickets) {
      return copyWith(tickets: _upsert(tickets, Ticket.fromRow(row), (item) => item.id));
    }
    final list = _upsert(notifications, AdminNotification.fromRow(row), (item) => item.id);
    return copyWith(notifications: list..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  AppData withoutRow(DbTable table, String id) {
    if (table == DbTable.customers) return copyWith(customers: customers.where((item) => item.id != id).toList());
    if (table == DbTable.conversations) return copyWith(conversations: {...conversations}..remove(id));
    if (table == DbTable.orders) return copyWith(orders: orders.where((item) => item.id != id).toList());
    if (table == DbTable.messages) return copyWith(messages: messages.where((item) => item.id != id).toList());
    if (table == DbTable.tickets) return copyWith(tickets: tickets.where((item) => item.id != id).toList());
    return copyWith(notifications: notifications.where((item) => item.id != id).toList());
  }

  AppData withAllRows(DbTable table, List<DbRow> rows) {
    if (table == DbTable.customers) {
      return copyWith(customers: rows.map(Customer.fromRow).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
    }
    if (table == DbTable.conversations) {
      return copyWith(conversations: {for (final row in rows) row['customer_id'] as String: Conversation.fromRow(row)});
    }
    if (table == DbTable.orders) {
      return copyWith(orders: rows.map(Order.fromRow).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }
    if (table == DbTable.messages) {
      return copyWith(messages: rows.map(Message.fromRow).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
    }
    if (table == DbTable.tickets) {
      return copyWith(tickets: rows.map(Ticket.fromRow).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }
    return copyWith(notifications: rows.map(AdminNotification.fromRow).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  AppData withRecentMessages(List<DbRow> rows, int since) {
    final fresh = rows.map(Message.fromRow).toList();
    final freshIds = fresh.map((item) => item.id).toSet();
    final older = messages.where((item) => item.createdAt <= since && !freshIds.contains(item.id));
    return copyWith(messages: [...older, ...fresh]..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  AppData withOlderMessages(List<DbRow> rows) {
    final known = messages.map((item) => item.id).toSet();
    final older = rows.where((row) => !known.contains(row['id'])).map(Message.fromRow);
    return copyWith(messages: [...older, ...messages]..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  AppData withMessagesFrom(int from) => copyWith(messages: messages.where((item) => item.createdAt > from).toList());

  List<T> _upsert<T>(List<T> list, T item, String Function(T) idOf) {
    final id = idOf(item);
    final index = list.indexWhere((existing) => idOf(existing) == id);
    if (index < 0) return [...list, item];
    return [...list]..[index] = item;
  }
}
