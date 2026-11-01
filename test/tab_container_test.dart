import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/features/shell/widgets/tab_container.dart';

Widget _tabs(int index) {
  return MaterialApp(
    home: TabContainer(index: index, children: const [Text('First'), Text('Second'), Text('Third'), Text('Fourth')]),
  );
}

void main() {
  testWidgets('only the selected tab stays on screen after a switch', (tester) async {
    await tester.pumpWidget(_tabs(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('First')).dx, 0);

    await tester.pumpWidget(_tabs(3));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Fourth')).dx, 0);
    expect(tester.getTopLeft(find.text('First')).dx, lessThan(0));
    expect(tester.getTopLeft(find.text('Second')).dx, lessThan(0));
    expect(tester.getTopLeft(find.text('Third')).dx, lessThan(0));

    await tester.pumpWidget(_tabs(1));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Second')).dx, 0);
    expect(tester.getTopLeft(find.text('Fourth')).dx, greaterThan(0));
  });
}
