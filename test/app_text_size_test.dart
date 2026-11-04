import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/core/widgets/app_text_size.dart';

double _scaleOn(WidgetTester tester) {
  final context = tester.element(find.text('size'));
  return MediaQuery.textScalerOf(context).scale(14) / 14;
}

Widget _app(double phoneSize) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(phoneSize)),
    child: const Directionality(textDirection: TextDirection.ltr, child: AppTextSize(child: Text('size'))),
  );
}

void main() {
  testWidgets('text is a little smaller than the phone setting', (tester) async {
    await tester.pumpWidget(_app(1));
    expect(_scaleOn(tester), closeTo(0.9, 0.001));
  });

  testWidgets('a very large phone font does not blow up the app', (tester) async {
    await tester.pumpWidget(_app(2));
    expect(_scaleOn(tester), closeTo(0.99, 0.001));
  });
}
