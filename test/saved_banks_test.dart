import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/data/models/store_config.dart';
import 'package:premium_store_admin/features/settings/widgets/saved_banks.dart';

StoreConfig _draft() {
  return StoreConfig(
    settings: {
      'bank': <String, dynamic>{'bankName': 'Meezan Bank', 'accountTitle': 'Premium Store', 'accountNumber': '0123 4567 8901', 'iban': ''},
      'savedBanks': [
        <String, dynamic>{'bankName': 'UBL', 'accountTitle': 'Muhammad Adeem', 'accountNumber': '1415 3035 4953 2', 'iban': ''},
      ],
    },
    plans: const [],
    methods: const [],
    faqs: const [],
  );
}

Future<StoreConfig> _show(WidgetTester tester) async {
  final draft = _draft();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SavedBanks(draft: draft, update: (change) => setState(() => change(draft))),
        ),
      ),
    ),
  );
  return draft;
}

void main() {
  testWidgets('tapping a saved account puts it in use', (tester) async {
    final draft = await _show(tester);
    await tester.tap(find.text('UBL'));
    await tester.pump();

    final bank = draft.settings['bank'] as Map;
    expect(bank['bankName'], 'UBL');
    expect(bank['accountNumber'], '1415 3035 4953 2');
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('the account in use can be saved once', (tester) async {
    final draft = await _show(tester);
    await tester.tap(find.text('Save this account'));
    await tester.pump();

    expect(savedBanksOf(draft).length, 2);
    expect(find.text('Meezan Bank'), findsOneWidget);
    expect(find.text('Save this account'), findsNothing);
  });
}
