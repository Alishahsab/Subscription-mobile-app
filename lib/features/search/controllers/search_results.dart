import '../../../data/models/customer.dart';
import '../../../data/models/message.dart';
import '../../../data/models/order.dart';
import '../../../data/sync/app_data.dart';
import '../../inbox/controllers/inbox_lists.dart';

const shownMessages = 50;
const _before = 40;
const _after = 80;

class SearchResults {
  const SearchResults({required this.messages, required this.customers, required this.orders});

  final List<Message> messages;
  final List<Customer> customers;
  final List<Order> orders;

  int get total => messages.length + customers.length + orders.length;
}

SearchResults searchEverything(AppData data, String query) {
  final words = query.trim().toLowerCase();
  if (words.isEmpty) return const SearchResults(messages: [], customers: [], orders: []);

  return SearchResults(
    messages: data.messages.where((item) => item.kind == 'text' && item.text.toLowerCase().contains(words)).toList(),
    customers: data.customers.where((item) {
      return item.email.toLowerCase().contains(words) || (item.whatsapp?.contains(words) ?? false) || customerTag(item).toLowerCase().contains(words);
    }).toList(),
    orders: data.orders.where((item) {
      return item.id.toLowerCase().contains(words) ||
          (item.senderName?.toLowerCase().contains(words) ?? false) ||
          (item.code?.toLowerCase().contains(words) ?? false);
    }).toList(),
  );
}

class Snippet {
  const Snippet(this.before, this.match, this.after);

  final String before;
  final String match;
  final String after;
}

Snippet snippetOf(String text, String query) {
  final index = text.toLowerCase().indexOf(query.toLowerCase());
  if (index < 0 || query.isEmpty) return Snippet(text, '', '');

  final start = index - _before < 0 ? 0 : index - _before;
  final end = index + query.length;
  final tailEnd = end + _after > text.length ? text.length : end + _after;

  return Snippet(
    '${start > 0 ? '…' : ''}${text.substring(start, index)}',
    text.substring(index, end),
    '${text.substring(end, tailEnd)}${tailEnd < text.length ? '…' : ''}',
  );
}
