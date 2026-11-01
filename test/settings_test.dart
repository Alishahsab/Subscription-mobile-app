import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/app/theme/app_colors.dart';
import 'package:premium_store_admin/app/theme/theme_controller.dart';
import 'package:premium_store_admin/core/utils/text_rules.dart';
import 'package:premium_store_admin/data/models/db_row.dart';
import 'package:premium_store_admin/data/models/store_config.dart';
import 'package:premium_store_admin/data/repositories/profile_repository.dart';
import 'package:premium_store_admin/data/sync/app_data.dart';
import 'package:premium_store_admin/data/sync/data_notifier.dart';
import 'package:premium_store_admin/data/sync/signal_notifier.dart';
import 'package:premium_store_admin/features/settings/controllers/settings_draft.dart';
import 'package:premium_store_admin/features/settings/controllers/settings_validation.dart';
import 'package:premium_store_admin/features/settings/screens/settings_screen.dart';
import 'package:premium_store_admin/features/settings/sections/appearance_section.dart';
import 'package:premium_store_admin/features/settings/sections/availability_section.dart';
import 'package:premium_store_admin/features/settings/sections/inbox_section.dart';
import 'package:premium_store_admin/features/settings/sections/payments_section.dart';
import 'package:premium_store_admin/features/settings/sections/support_section.dart';
import 'package:premium_store_admin/features/settings/sections/timers_section.dart';
import 'package:premium_store_admin/features/settings/widgets/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuietSignal extends SignalNotifier {
  @override
  Signal build() => const Signal(4, 300);
}

class _Data extends DataNotifier {
  @override
  AppData build() => AppData(loaded: true, config: goodConfig());
}

class _NoProfile extends AdminProfileNotifier {
  @override
  AdminProfile? build() => const AdminProfile(userId: 'u', email: 'admin@store.com', name: 'Admin');
}

StoreConfig goodConfig() {
  return StoreConfig.fromRow({
    'settings': <String, dynamic>{
      'howItWorks': 'Pick a plan and pay.',
      'terms': ['Pay in {timer} minutes.'],
      'usageSteps': [
        {'id': 'u1', 'text': 'Open the app.'},
      ],
      'nextTimeSteps': [
        {'id': 'n1', 'text': 'Create a new order.'},
      ],
      'bank': {'bankName': 'Meezan Bank', 'accountTitle': 'Premium Store', 'accountNumber': '0123 4567 8901'},
      'quickReplies': ['Payment received', 'Please wait'],
      'inboxTabs': [
        {'key': 'pending', 'label': 'Pending'},
        {'key': 'issues', 'label': 'App issues'},
        {'key': 'completed', 'label': 'Completed'},
        {'key': 'unused', 'label': 'Unused codes'},
        {'key': 'blocked', 'label': 'Blocked'},
      ],
    },
    'plans': <dynamic>[
      {'id': 'p1', 'name': '1 Month', 'months': 1, 'price': 299, 'active': true},
    ],
    'methods': <dynamic>[
      {'id': 'jazzcash', 'name': 'JazzCash', 'active': true, 'steps': '1. Open the app\n2. Send money'},
    ],
    'faqs': <dynamic>[
      {'id': 'f1', 'question': 'Can I get a refund?', 'answer': 'No.'},
    ],
  });
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
        adminProfileProvider.overrideWith(_NoProfile.new),
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
  test('missing saved settings fall back to the defaults', () {
    final config = goodConfig();

    expect(config.settings['storeName'], 'Premium Store');
    expect((config.settings['timers'] as DbRow)['orderMinutes'], 15);
    expect((config.settings['messages'] as DbRow)['menuPrompt'], 'What can we help you with?');
  });

  test('a saved value wins over the default inside a group', () {
    final config = StoreConfig.fromRow({
      'settings': <String, dynamic>{
        'timers': {'orderMinutes': 20},
      },
      'plans': <dynamic>[],
      'methods': <dynamic>[],
      'faqs': <dynamic>[],
    });

    final timers = config.settings['timers'] as DbRow;
    expect(timers['orderMinutes'], 20);
    expect(timers['inactiveMinutes'], 20);
    expect(timers['cancelWindowMinutes'], 5);
  });

  test('old guide text turns into steps', () {
    final config = StoreConfig.fromRow({
      'settings': <String, dynamic>{'activationGuide': '1. Open\n2) Paste'},
      'plans': <dynamic>[],
      'methods': <dynamic>[],
      'faqs': <dynamic>[],
    });

    final steps = (config.settings['usageSteps'] as List).cast<DbRow>();
    expect(steps.map((step) => step['text']), ['Open', 'Paste']);
  });

  test('a good config passes validation', () {
    expect(validateConfig(goodConfig()), isEmpty);
  });

  test('validation gives the same messages as the web', () {
    final config = copyConfig(goodConfig());
    config.settings['welcome'] = '  ';
    (config.settings['bank'] as DbRow)['accountNumber'] = '123';
    (config.plans.first as DbRow)['price'] = 0;
    (config.methods.first as DbRow)['active'] = false;
    (config.methods.first as DbRow)['showIban'] = true;

    expect(
      validateConfig(config),
      containsAll([
        'Welcome message cannot be empty.',
        'Account number must be 8 to 20 digits.',
        'Price for 1 Month must be between 1 and 999,999.',
        'At least one payment method must be shown.',
        'Add the IBAN, or turn off Show IBAN for every payment method.',
      ]),
    );
  });

  test('saving cleans empty lines, empty FAQs and step numbers', () {
    final draft = copyConfig(goodConfig());
    draft.settings['terms'] = [' Rule one ', '', '   '];
    draft.faqs.add(<String, dynamic>{'id': 'f2', 'question': '', 'answer': 'x'});

    final clean = cleanDraft(draft);
    expect(clean.settings['terms'], ['Rule one']);
    expect(clean.faqs.length, 1);
    expect((clean.methods.first as DbRow)['steps'], 'Open the app\nSend money');
  });

  test('the status does not count as a settings change', () {
    final first = copyConfig(goodConfig());
    final second = copyConfig(goodConfig());
    second.settings['status'] = 'offline';

    expect(draftSnapshot(first), draftSnapshot(second));
  });

  test('text fields clean the same way as the web', () {
    expect(cleanLetters('  Meezan  Bank 1'), 'Meezan Bank ');
    expect(cleanLettersAndDigits('3 Months!'), '3 Months');
    expect(cleanAccountNumber('0123-4567 8901'), '0123 4567 8901');
    expect(cleanIban('pk36 scbl 00'), 'PK36 SCBL 00');
    expect(stepLines('1. One\n\n2) Two'), ['One', 'Two']);
  });

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    for (final dark in const [false, true]) {
      final label = '${size.width.toInt()} wide, dark $dark';

      testWidgets('settings home draws on $label', (tester) async {
        await _pump(tester, const SettingsScreen(), size: size, dark: dark);
        expect(find.text('Availability'), findsOneWidget);
        expect(find.text('admin@store.com'), findsOneWidget);
      });

      final sections = <String, PageBuilder>{
        'availability': (context, draft, update) => AvailabilitySection(draft: draft, update: update),
        'payments': (context, draft, update) => PaymentsSection(draft: draft, update: update),
        'support': (context, draft, update) => SupportSection(draft: draft, update: update),
        'inbox': (context, draft, update) => InboxSection(draft: draft, update: update),
        'timers': (context, draft, update) => TimersSection(draft: draft, update: update),
        'appearance': (context, draft, update) => AppearanceSection(draft: draft, update: update),
      };

      sections.forEach((name, builder) {
        testWidgets('$name section draws on $label', (tester) async {
          await _pump(tester, SettingsPage(title: name, builder: builder), size: size, dark: dark);
          expect(find.text(name), findsOneWidget);
        });
      });
    }
  }

  testWidgets('editing shows the save bar and Discard brings the live value back', (tester) async {
    await _pump(tester, SettingsPage(title: 'Timers', builder: (context, draft, update) => TimersSection(draft: draft, update: update)));

    expect(find.text('Save changes'), findsNothing);
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pump();
    expect(find.text('16'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pump();
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('switching the timer unit keeps the number, like the web', (tester) async {
    await _pump(tester, SettingsPage(title: 'Timers', builder: (context, draft, update) => TimersSection(draft: draft, update: update)));

    await tester.tap(find.text('hr').first);
    await tester.pump();
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
  });

  testWidgets('searching settings hides the rest', (tester) async {
    await _pump(tester, const SettingsScreen());
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'colour');
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Availability'), findsNothing);
    expect(find.text('Sign out'), findsNothing);
  });
}
