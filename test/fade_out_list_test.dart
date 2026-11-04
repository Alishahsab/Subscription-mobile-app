import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/core/widgets/fade_out_list.dart';

Widget _list(List<String> items) {
  return MaterialApp(
    home: Scaffold(
      body: FadeOutList<String>(
        items: items,
        keyOf: (item) => item,
        itemBuilder: (item) => SizedBox(height: 60, child: Text(item)),
        empty: const Text('Nothing here'),
      ),
    ),
  );
}

void main() {
  testWidgets('a removed row fades out before it goes, and the others keep their order', (tester) async {
    await tester.pumpWidget(_list(['first', 'second', 'third']));
    await tester.pumpWidget(_list(['first', 'third']));

    expect(find.text('second'), findsOneWidget);
    final order = tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList();
    expect(order, ['first', 'second', 'third']);

    await tester.pumpAndSettle();
    expect(find.text('second'), findsNothing);
    expect(find.text('first'), findsOneWidget);
    expect(find.text('third'), findsOneWidget);
  });

  testWidgets('the last row fading out leaves the empty message', (tester) async {
    await tester.pumpWidget(_list(['only']));
    await tester.pumpWidget(_list([]));
    await tester.pumpAndSettle();

    expect(find.text('only'), findsNothing);
    expect(find.text('Nothing here'), findsOneWidget);
  });
}
