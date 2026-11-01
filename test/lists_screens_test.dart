import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/app/theme/app_colors.dart';
import 'package:premium_store_admin/app/theme/theme_controller.dart';
import 'package:premium_store_admin/data/models/db_row.dart';
import 'package:premium_store_admin/data/models/store_config.dart';
import 'package:premium_store_admin/data/sync/app_data.dart';
import 'package:premium_store_admin/data/sync/data_notifier.dart';
import 'package:premium_store_admin/data/sync/db_table.dart';
import 'package:premium_store_admin/data/sync/now_provider.dart';
import 'package:premium_store_admin/data/sync/signal_notifier.dart';
import 'package:premium_store_admin/features/bot_chat/screens/bot_chat_screen.dart';
import 'package:premium_store_admin/features/customers/screens/customers_screen.dart';
import 'package:premium_store_admin/features/inbox/controllers/inbox_lists.dart';
import 'package:premium_store_admin/features/inbox/controllers/inbox_navigation.dart';
import 'package:premium_store_admin/features/search/controllers/search_results.dart';
import 'package:premium_store_admin/features/search/screens/search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuietSignal extends SignalNotifier {
  @override
  Signal build() => const Signal(4, 300);
}

class _Data extends DataNotifier {
  @override
  AppData build() => _sample();
}

int get _now => DateTime.now().millisecondsSinceEpoch;

DbRow _customer(int index, {bool blocked = false, int? lastSeen, String? whatsapp}) {
  return {
    'id': 'c$index',
    'customer_number': 2000 + index,
    'email': 'customer$index@gmail.com',
    'whatsapp': whatsapp,
    'created_at': 1,
    'last_seen_at': lastSeen ?? _now - 1000,
    'blocked': blocked,
  };
}

DbRow _order(String id, String status, String customerId, {String? code, int? expiresAt, int? reviewedAt}) {
  return {
    'id': id,
    'customer_id': customerId,
    'plan_id': 'p',
    'plan_name': '3 Months',
    'amount': 769,
    'method_name': 'Easypaisa',
    'status': status,
    'created_at': _now - 60000,
    'expires_at': expiresAt ?? _now + 600000,
    'reviewed_at': reviewedAt,
    'sender_name': 'Ghulam Abbas',
    'code': code,
    'code_unused': false,
  };
}

DbRow _message(String id, String customerId, String sender, String text, {String kind = 'text'}) {
  return {'id': id, 'customer_id': customerId, 'sender': sender, 'kind': kind, 'text': text, 'created_at': _now - 5000};
}

AppData _sample() {
  var data = const AppData(loaded: true);
  data = data.withAllRows(DbTable.customers, [
    _customer(0, whatsapp: '03001234560'),
    _customer(1, lastSeen: _now - 2 * Duration.millisecondsPerDay),
    _customer(2, blocked: true, whatsapp: '03001234562'),
  ]);
  data = data.withAllRows(DbTable.conversations, [
    {'customer_id': 'c0', 'stage': 'menu', 'unread_by_admin': 2, 'last_message_at': _now},
    {'customer_id': 'c1', 'stage': 'menu', 'unread_by_admin': 0, 'last_message_at': _now},
  ]);
  data = data.withAllRows(DbTable.messages, [
    _message('m1', 'c0', 'customer', 'Please help me with the code'),
    _message('m2', 'c1', 'admin', 'Thanks for waiting'),
    _message('m3', 'c1', 'admin', 'Your code', kind: 'code'),
  ]);
  data = data.withAllRows(DbTable.orders, [
    _order('PS-A', 'awaiting_payment', 'c0'),
    _order('PS-B', 'expired', 'c1', expiresAt: _now - 60000),
    _order('PS-C', 'cancelled', 'c1', reviewedAt: _now - 30000),
    _order('PS-D', 'completed', 'c2', code: 'ABC123'),
  ]);
  return data.copyWith(config: const StoreConfig(settings: {}, plans: [], methods: [], faqs: []));
}

Future<void> _pump(WidgetTester tester, Widget screen, {Size size = const Size(390, 844), bool dark = false, String? filter}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        signalProvider.overrideWith(_QuietSignal.new),
        dataProvider.overrideWith(_Data.new),
        nowProvider.overrideWith((ref) => Stream.value(_now)),
        if (filter != null) botFilterProvider.overrideWith((ref) => filter),
      ],
      child: MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, surface: Colors.white)),
        darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, brightness: Brightness.dark)),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(body: screen),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('search finds messages, customers and orders', () {
    final data = _sample();

    expect(searchEverything(data, '  ').total, 0);
    expect(searchEverything(data, 'HELP').messages.single.id, 'm1');
    expect(searchEverything(data, 'customer1@').customers.single.id, 'c1');
    expect(searchEverything(data, '#2002').customers.single.id, 'c2');
    expect(searchEverything(data, '03001234560').customers.single.id, 'c0');
    expect(searchEverything(data, 'abc123').orders.single.id, 'PS-D');
    expect(searchEverything(data, 'ps-b').orders.single.id, 'PS-B');
    expect(searchEverything(data, 'Your code').messages, isEmpty);
  });

  test('a search snippet keeps text around the match', () {
    final long = '${'a' * 60} match ${'b' * 100}';
    final snippet = snippetOf(long, 'MATCH');

    expect(snippet.match, 'match');
    expect(snippet.before.startsWith('…'), isTrue);
    expect(snippet.before.length, 41);
    expect(snippet.after.endsWith('…'), isTrue);
    expect(snippetOf('short text', 'short').before, '');
  });

  test('cancelled orders say why, newest first', () {
    final items = cancelledItems(_sample(), _now);

    expect(items.map((item) => item.key), ['PS-C', 'PS-B']);
    expect(items.first.badge, startsWith('Cancelled by customer · '));
    expect(items.last.badge, startsWith('Time ran out · '));
  });

  test('chat lists split active and inactive customers', () {
    final data = _sample();
    final active = botItems(data, BotFilter.activeChats, _now);
    final inactive = botItems(data, BotFilter.inactiveChats, _now);

    expect(active.single.customerId, 'c0');
    expect(active.single.subtitle, 'Please help me with the code');
    expect(inactive.single.customerId, 'c1');
    expect(inactive.single.subtitle, 'You: Code sent');
    expect(inactive.single.badge, startsWith('Inactive · '));
  });

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    for (final dark in const [false, true]) {
      for (final filter in const [BotFilter.activeChats, BotFilter.activeOrders, BotFilter.cancelled, BotFilter.inactiveChats]) {
        testWidgets('bot chat $filter draws on ${size.width.toInt()} wide, dark $dark', (tester) async {
          await _pump(tester, const BotChatScreen(), size: size, dark: dark, filter: filter);
          expect(find.text('Bot chat'), findsOneWidget);
        });
      }

      testWidgets('customers draw on ${size.width.toInt()} wide, dark $dark', (tester) async {
        await _pump(tester, const CustomersScreen(), size: size, dark: dark);
        expect(find.text('Customers'), findsOneWidget);
        expect(find.text('No WhatsApp'), findsOneWidget);
      });

      testWidgets('search draws on ${size.width.toInt()} wide, dark $dark', (tester) async {
        await _pump(tester, const SearchResultsView(query: 'c'), size: size, dark: dark);
        expect(find.text('Messages'), findsOneWidget);
        expect(find.text('Customers'), findsOneWidget);
      });
    }
  }

  testWidgets('customer filters show the right rows', (tester) async {
    await _pump(tester, const CustomersScreen());

    expect(find.text('Chat'), findsNWidgets(3));
    expect(find.text('Unblock'), findsOneWidget);

    await tester.tap(find.text('Blocked'));
    await tester.pump();
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('customer2@gmail.com'), findsOneWidget);
  });

  testWidgets('search with nothing found says so', (tester) async {
    await _pump(tester, const SearchResultsView(query: 'zzzz'));

    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('0 results for "zzzz"'), findsOneWidget);
  });
}
