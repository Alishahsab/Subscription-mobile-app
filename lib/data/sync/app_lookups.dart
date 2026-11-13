import '../models/customer.dart';
import '../models/message.dart';
import '../models/order.dart';
import '../models/ticket.dart';
import 'app_data.dart';

final _customersById = Expando<Map<String, Customer>>();
final _ordersById = Expando<Map<String, Order>>();
final _ticketsById = Expando<Map<String, Ticket>>();
final _openIssueCustomers = Expando<Set<String>>();
final _ordersByCustomer = Expando<Map<String, List<Order>>>();
final _messagesByCustomer = Expando<Map<String, List<Message>>>();
final _lastSentByCustomer = Expando<Map<String, int>>();

extension AppLookups on AppData {
  Customer? customer(String id) {
    final lookup = _customersById[customers] ??= {for (final item in customers) item.id: item};
    return lookup[id];
  }

  Order? order(String id) {
    final lookup = _ordersById[orders] ??= {for (final item in orders) item.id: item};
    return lookup[id];
  }

  Ticket? ticket(String id) {
    final lookup = _ticketsById[tickets] ??= {for (final item in tickets) item.id: item};
    return lookup[id];
  }

  bool hasOpenIssue(String customerId) {
    final lookup = _openIssueCustomers[tickets] ??= {
      for (final item in tickets)
        if (item.kind == 'support' && item.status == 'open') item.customerId,
    };
    return lookup.contains(customerId);
  }

  List<Order> ordersOf(String customerId) {
    final lookup = _ordersByCustomer[orders] ??= _groupOrders();
    return lookup[customerId] ?? const [];
  }

  List<Message> messagesOf(String customerId) {
    final lookup = _messagesByCustomer[messages] ??= _groupMessages();
    return lookup[customerId] ?? const [];
  }

  int lastCustomerMessageAt(String customerId) {
    final lookup = _lastSentByCustomer[messages] ??= _lastSent();
    return lookup[customerId] ?? 0;
  }

  Map<String, List<Order>> _groupOrders() {
    final grouped = <String, List<Order>>{};
    for (final order in orders) {
      grouped.putIfAbsent(order.customerId, () => []).add(order);
    }
    return grouped;
  }

  Map<String, List<Message>> _groupMessages() {
    final grouped = <String, List<Message>>{};
    for (final message in messages) {
      grouped.putIfAbsent(message.customerId, () => []).add(message);
    }
    return grouped;
  }

  Map<String, int> _lastSent() {
    final lastSent = <String, int>{};
    for (final message in messages) {
      if (message.sender != 'customer') continue;
      final current = lastSent[message.customerId] ?? 0;
      if (message.createdAt > current) lastSent[message.customerId] = message.createdAt;
    }
    return lastSent;
  }
}
