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
import 'package:premium_store_admin/core/widgets/signal_button.dart';
import 'package:premium_store_admin/data/sync/signal_notifier.dart';
import 'package:premium_store_admin/features/dashboard/screens/dashboard_screen.dart';
import 'package:premium_store_admin/features/inbox/widgets/card_button.dart';
import 'package:premium_store_admin/features/inbox/controllers/inbox_navigation.dart';
import 'package:premium_store_admin/features/inbox/screens/inbox_screen.dart';
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

DbRow _order(String id, String status, String customerId, {String? code, bool unused = false, String? reason, String sender = 'Ghulam Abbas'}) {
  return {
    'id': id,
    'customer_id': customerId,
    'plan_id': 'p',
    'plan_name': '3 Months',
    'amount': 769,
    'method_name': 'Easypaisa',
    'status': status,
    'created_at': _now - 60000,
    'expires_at': _now + 600000,
    'submitted_at': _now - 30000,
    'reviewed_at': _now - 20000,
    'sender_name': sender,
    'reject_reason': reason,
    'code': code,
    'code_unused': unused,
  };
}

DbRow _customer(int index, {bool blocked = false}) {
  return {
    'id': 'c$index',
    'customer_number': 2000 + index,
    'email': 'customer$index@gmail.com',
    'whatsapp': '0300123456$index',
    'created_at': 1,
    'last_seen_at': _now - 1000,
    'blocked': blocked,
    'block_reason': blocked ? 'Too many cancelled orders' : null,
  };
}

AppData _sample() {
  var data = const AppData(loaded: true);
  data = data.withAllRows(DbTable.customers, [for (var index = 0; index < 6; index++) _customer(index, blocked: index == 5)]);
  data = data.withAllRows(DbTable.orders, [
    _order('PS-1', 'pending_review', 'c0'),
    _order('PS-2', 'rejected', 'c1', reason: 'Screenshot is unclear'),
    _order('PS-3', 'completed', 'c2', code: 'ABC123'),
    _order('PS-4', 'completed', 'c3', code: 'XYZ789', unused: true),
  ]);
  data = data.withAllRows(DbTable.tickets, [
    {'id': 'T-1', 'customer_id': 'c4', 'kind': 'support', 'message': 'App is not opening after I paste the code', 'status': 'open', 'created_at': _now},
  ]);
  data = data.withAllRows(DbTable.conversations, [
    {'customer_id': 'c0', 'stage': 'awaiting_payment', 'unread_by_admin': 1, 'last_message_at': _now},
  ]);
  data = data.withAllRows(DbTable.messages, [
    {'id': 'm1', 'customer_id': 'c0', 'sender': 'customer', 'kind': 'text', 'text': 'Create order', 'created_at': _now - 5000},
  ]);
  return data.copyWith(
    config: const StoreConfig(
      settings: {
        'status': 'active',
        'rejectReasons': ['Screenshot is unclear', 'Amount does not match'],
      },
      plans: [],
      methods: [],
      faqs: [],
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget screen, {Size size = const Size(390, 844), bool dark = false, String? tab}) async {
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
        
        inboxTabProvider.overrideWith((ref) => tab),
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
  for (final size in const [Size(390, 844), Size(320, 568)]) {
    for (final dark in const [false, true]) {
      testWidgets('dashboard draws on ${size.width.toInt()} wide, dark $dark', (tester) async {
        await _pump(tester, const DashboardScreen(), size: size, dark: dark);

        expect(find.text('Needs your review'), findsOneWidget);
        expect(find.text('Completed orders'), findsOneWidget);
        expect(find.text('Customer list'), findsOneWidget);
        expect(find.text('6 customers · tap to see all'), findsOneWidget);
      });

      for (final tab in const ['pending', 'issues', 'completed', 'unused', 'blocked']) {
        testWidgets('inbox $tab draws on ${size.width.toInt()} wide, dark $dark', (tester) async {
          await _pump(tester, const InboxScreen(), size: size, dark: dark, tab: tab);
          expect(find.text('Inbox'), findsOneWidget);
          expect(find.text('Pending'), findsOneWidget);
        });
      }
    }
  }

  testWidgets('the home header shows the store pill, search and signal in their places', (tester) async {
    await _pump(tester, const DashboardScreen());

    final pill = tester.getTopLeft(find.text('Premium Store'));
    final search = tester.getCenter(find.byIcon(Icons.search_rounded));
    final signal = tester.getCenter(find.byType(SignalButton));

    expect(pill.dx, lessThan(120));
    expect(search.dx, greaterThan(280));
    expect(signal.dx, greaterThan(search.dx));
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('pending cards show their details and buttons', (tester) async {
    await _pump(tester, const InboxScreen(), tab: 'pending');

    expect(find.text('Approve'), findsNWidgets(2));
    expect(find.text('Rejected: Screenshot is unclear'), findsOneWidget);
    expect(find.text('Ghulam Abbas'), findsNWidgets(2));
    expect(find.text('3 Months · Rs 769 · Easypaisa'), findsNWidgets(2));
  });

  testWidgets('card buttons are only as wide as their text', (tester) async {
    await _pump(tester, const InboxScreen(), tab: 'pending');

    for (final label in ['Approve', 'Reject', 'Cancel']) {
      final text = tester.getSize(find.text(label).first).width;
      final button = tester.getSize(find.widgetWithText(CardButton, label).first).width;
      expect(button, text + 28);
    }
  });

  testWidgets('approve finds the code and refuses one already sent', (tester) async {
    await _pump(tester, const InboxScreen(), tab: 'pending');
    await tester.tap(find.text('Approve').first);
    await tester.pumpAndSettle();

    final field = find.widgetWithText(TextField, 'Code message');
    await tester.enterText(field, 'Your premium code for 3 months is:\n\nNEW456\n\nPlease copy it');
    await tester.pump();
    expect(find.text('Code found: NEW456'), findsOneWidget);

    await tester.enterText(field, 'Your premium code for 3 months is:\n\nABC123\n\nPlease copy it');
    await tester.pump();
    expect(find.textContaining('was already sent to customer2@gmail.com'), findsOneWidget);

    await tester.enterText(field, 'no code here');
    await tester.pump();
    expect(find.text('No code found, please type the code'), findsOneWidget);
  });

  testWidgets('reject needs a written reason when that option is picked', (tester) async {
    await _pump(tester, const InboxScreen(), tab: 'pending');
    await tester.tap(find.text('Reject').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Write a reason'));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Reject'));
    expect(button.onPressed, isNull);
  });

  testWidgets('search narrows the list', (tester) async {
    await _pump(tester, const InboxScreen(), tab: 'pending');
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nothing like this');
    await tester.pump();

    expect(find.text('No match for your search.'), findsOneWidget);
  });
}
