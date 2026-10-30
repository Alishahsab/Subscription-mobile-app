import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/features/notifications/code_finder.dart';

void main() {
  test('finds the code on its own line of the portal message', () {
    const message = "Your premium code for 1 month is:\n\n 7PNE9R\n\nPlease copy and paste it in the App 'Activate with Premium Code'.";
    expect(findCode(message), '7PNE9R');
  });

  test('takes a pasted code on its own', () {
    expect(findCode(' 8LFNBS '), '8LFNBS');
  });

  test('finds the code after a colon', () {
    expect(findCode('Your code is: AB12CD enjoy'), 'AB12CD');
  });

  test('gives nothing when there is no code', () {
    expect(findCode('Thank you for your payment'), '');
  });
}
