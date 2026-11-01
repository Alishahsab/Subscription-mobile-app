import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/app/theme/app_colors.dart';
import 'package:premium_store_admin/app/theme/theme_controller.dart';
import 'package:premium_store_admin/data/models/db_row.dart';
import 'package:premium_store_admin/data/models/message.dart';
import 'package:premium_store_admin/data/models/store_config.dart';
import 'package:premium_store_admin/data/repositories/admin_actions.dart';
import 'package:premium_store_admin/data/sync/app_data.dart';
import 'package:premium_store_admin/data/sync/data_notifier.dart';
import 'package:premium_store_admin/data/sync/db_table.dart';
import 'package:premium_store_admin/data/sync/now_provider.dart';
import 'package:premium_store_admin/data/sync/signal_notifier.dart';
import 'package:premium_store_admin/features/chat/controllers/chat_grouping.dart';
import 'package:premium_store_admin/features/chat/screens/customer_details_screen.dart';
import 'package:premium_store_admin/features/chat/widgets/message_tile.dart';
import 'package:premium_store_admin/features/chat/widgets/reply_box.dart';
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

DbRow _order(String id, String status, {String? code, bool unused = false, String? reason}) {
  return {
    'id': id,
    'customer_id': 'c1',
    'plan_id': 'p',
    'plan_name': '3 Months',
    'amount': 769,
    'method_name': 'Easypaisa',
    'status': status,
    'created_at': _now - 60000,
    'expires_at': _now + 600000,
    'submitted_at': _now - 30000,
    'reviewed_at': _now - 20000,
    'sender_name': 'Ghulam Abbas',
    'reject_reason': reason,
    'code': code,
    'code_unused': unused,
  };
}

Message _message(String id, String sender, String kind, {String text = 'Hello there', String? orderId, String? image, int minutesAgo = 1}) {
  return Message(id: id, customerId: 'c1', sender: sender, kind: kind, text: text, orderId: orderId, image: image, createdAt: _now - minutesAgo * 60000);
}

AppData _sample({bool blocked = false, String stage = 'menu'}) {
  var data = const AppData(loaded: true);
  data = data.withAllRows(DbTable.customers, [
    {
      'id': 'c1',
      'customer_number': 2079,
      'email': 'customer@gmail.com',
      'whatsapp': '03009219137',
      'created_at': _now,
      'last_seen_at': _now,
      'blocked': blocked,
      'block_reason': blocked ? 'Fake payment screenshot' : null,
    },
  ]);
  data = data.withAllRows(DbTable.conversations, [
    {'customer_id': 'c1', 'stage': stage, 'unread_by_admin': 0, 'last_message_at': _now},
  ]);
  data = data.withAllRows(DbTable.orders, [
    _order('PS-1', 'pending_review'),
    _order('PS-2', 'rejected', reason: 'Screenshot is unclear'),
    _order('PS-3', 'completed', code: 'ABC123'),
    _order('PS-4', 'completed'),
  ]);
  data = data.withAllRows(DbTable.tickets, [
    {'id': 'T-1', 'customer_id': 'c1', 'kind': 'support', 'message': 'App is not opening', 'status': 'open', 'created_at': _now},
    {'id': 'T-2', 'customer_id': 'c1', 'kind': 'payment', 'message': 'Money was taken', 'status': 'open', 'created_at': _now},
    {'id': 'T-3', 'customer_id': 'c1', 'kind': 'support', 'message': 'Old issue', 'status': 'resolved', 'created_at': 1},
  ]);
  return data.copyWith(
    config: const StoreConfig(
      settings: {
        'quickReplies': ['Thank you', ' '],
      },
      plans: [],
      methods: [],
      faqs: [],
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget screen, {Size size = const Size(390, 844), bool dark = false}) async {
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
      ],
      child: MaterialApp(
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, surface: Colors.white)),
        darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, brightness: Brightness.dark)),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: screen,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  test('a group ends on a new sender, a five minute gap or a new day', () {
    final first = _message('a', 'customer', 'text', minutesAgo: 10);
    expect(endsGroup(first, null), isTrue);
    expect(endsGroup(first, _message('b', 'customer', 'text', minutesAgo: 9)), isFalse);
    expect(endsGroup(first, _message('c', 'admin', 'text', minutesAgo: 9)), isTrue);
    expect(endsGroup(first, _message('d', 'customer', 'text', minutesAgo: 2)), isTrue);
    expect(startsDay(first, null), isTrue);
  });

  test('only plain admin messages can be deleted', () {
    expect(canDeleteMessage(_message('a', 'admin', 'text')), isTrue);
    expect(canDeleteMessage(_message('b', 'admin', 'image')), isTrue);
    expect(canDeleteMessage(_message('c', 'admin', 'code')), isFalse);
    expect(canDeleteMessage(_message('d', 'bot', 'text')), isFalse);
  });

  test('the chat stage after a reply follows the web rules', () {
    final data = _sample();
    expect(stageAfterReply(data, 'c1', containsCode: true, ticketReply: false)['stage'], 'code_delivered');
    expect(stageAfterReply(data, 'c1', containsCode: false, ticketReply: true)['stage'], 'agent_replied');
    expect(stageAfterReply(data, 'c1', containsCode: false, ticketReply: false)['stage'], 'waiting_agent');

    final replied = _sample(stage: 'agent_replied');
    expect(stageAfterReply(replied, 'c1', containsCode: false, ticketReply: false).containsKey('stage'), isFalse);

    final noIssue = data.withAllRows(DbTable.tickets, []);
    final pending = stageAfterReply(noIssue, 'c1', containsCode: false, ticketReply: false);
    expect(pending['stage'], 'awaiting_payment');
    expect(pending['active_order_id'], 'PS-1');

    final quiet = noIssue.withAllRows(DbTable.orders, []);
    expect(stageAfterReply(quiet, 'c1', containsCode: false, ticketReply: false)['stage'], 'live');
    final waiting = quiet.withAllRows(DbTable.conversations, [
      {'customer_id': 'c1', 'stage': 'rejected', 'unread_by_admin': 0, 'last_message_at': 1},
    ]);
    expect(stageAfterReply(waiting, 'c1', containsCode: false, ticketReply: false).containsKey('stage'), isFalse);
  });

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    for (final dark in const [false, true]) {
      testWidgets('every message kind draws on ${size.width.toInt()} wide, dark $dark', (tester) async {
        final messages = [
          _message('1', 'customer', 'text', text: 'A long message from the customer that has to wrap over more than one line here'),
          _message('2', 'bot', 'text', text: 'Auto reply'),
          _message('3', 'admin', 'text'),
          _message('4', 'admin', 'code', text: 'Your premium code\n\nABC123', orderId: 'PS-3'),
          _message('5', 'customer', 'proof', orderId: 'PS-1'),
          _message('6', 'admin', 'deleted', text: ''),
          _message('7', 'customer', 'image'),
          _message('8', 'admin', 'image'),
          _message('9', 'bot', 'payment', orderId: 'PS-1'),
          _message('10', 'bot', 'steps'),
          _message('11', 'bot', 'instructions'),
          _message('12', 'bot', 'payment', text: 'Order created'),
        ];
        final orders = _sample().orders;

        await _pump(
          tester,
          Scaffold(
            body: ListView(
              children: [
                for (final message in messages)
                  MessageTile(message: message, order: orders.where((item) => item.id == message.orderId).firstOrNull, showMeta: true),
              ],
            ),
          ),
          size: size,
          dark: dark,
        );

        expect(find.textContaining('Auto-reply'), findsOneWidget);
        expect(find.text('Code sent · ABC123'), findsOneWidget);
      });

      testWidgets('customer details draw on ${size.width.toInt()} wide, dark $dark', (tester) async {
        await _pump(tester, const CustomerDetailsScreen(customerId: 'c1'), size: size, dark: dark);
        expect(find.text('Completed orders'), findsOneWidget);
        expect(find.textContaining('Customer since'), findsOneWidget);
      });
    }
  }

  testWidgets('details show the right orders, counts and buttons', (tester) async {
    await _pump(tester, const CustomerDetailsScreen(customerId: 'c1'), size: const Size(390, 4000));

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Mark as unused'), findsOneWidget);
    expect(find.textContaining('Type the premium code in the chat'), findsOneWidget);
    expect(find.textContaining('Rejected: Screenshot is unclear.'), findsOneWidget);
    expect(find.text('Approve'), findsNWidgets(2));
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Resolved'), findsNWidgets(2));
    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Old issue'), findsNothing);
  });

  testWidgets('reply box enables send, shows quick replies and hides empty ones', (tester) async {
    await _pump(tester, const Scaffold(body: Align(alignment: Alignment.bottomCenter, child: ReplyBox(customerId: 'c1'))));

    FilledButton send() => tester.widget<FilledButton>(find.byType(FilledButton));
    expect(send().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();
    expect(send().onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.chat_outlined));
    await tester.pump();
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text(' '), findsNothing);
  });
}
