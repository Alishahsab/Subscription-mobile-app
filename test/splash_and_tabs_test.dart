import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/features/shell/widgets/floating_tab_bar.dart';
import 'package:premium_store_admin/features/splash/screens/splash_screen.dart';

void main() {
  testWidgets('the splash shows the store name and finishes quickly', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onDone: () => done = true)));

    expect(find.text('PREMIUM STORE'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(done, isTrue);
  });

  testWidgets('every tab shows its name and a tap selects another', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FloatingTabBar(index: selected, onSelect: (index) => setState(() => selected = index)),
          ),
        ),
      ),
    );

    for (final label in ['Home', 'Inbox', 'Bot', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('the inbox tab shows how many things are waiting', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FloatingTabBar(index: 0, onSelect: (_) {}, inboxCount: 3))));
    expect(find.text('3'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FloatingTabBar(index: 1, onSelect: (_) {}, inboxCount: 3))));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsNothing);
  });
}
