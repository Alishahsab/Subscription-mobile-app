import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/core/utils/plan_check.dart';

void main() {
  test('a code message for another plan is stopped', () {
    expect(planMismatch('Your premium code for 3 month is: AB12CD', '1 Month'), contains('3 Months'));
    expect(planMismatch('Your premium code for 1 year is: AB12CD', '6 Months'), contains('12 Months'));
  });

  test('a matching or plain message goes through', () {
    expect(planMismatch('Your premium code for 1 month is: AB12CD', '1 Month'), isNull);
    expect(planMismatch('Code for 12 months: AB12CD', '12 Months'), isNull);
    expect(planMismatch('AB12CD', '3 Months'), isNull);
  });
}
