class DbTable {
  const DbTable(this.name, this.key);

  final String name;
  final String key;

  static const customers = DbTable('customers', 'id');
  static const conversations = DbTable('conversations', 'customer_id');
  static const orders = DbTable('orders', 'id');
  static const messages = DbTable('messages', 'id');
  static const tickets = DbTable('tickets', 'id');
  static const notifications = DbTable('notifications', 'id');

  static const all = [customers, conversations, orders, messages, tickets, notifications];
}
