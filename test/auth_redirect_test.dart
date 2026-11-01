import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/app/router.dart';
import 'package:premium_store_admin/features/shell/screens/main_shell.dart';

void main() {
  test('a notification opens the chat of its customer', () {
    expect(chatPathFor({'section': 'inbox', 'tab': 'pending', 'customerId': 'c1'}), AppRoutes.chat('c1'));
    expect(chatPathFor({'section': 'inbox', 'tab': 'pending', 'rejectOrderId': 'PS-1'}), isNull);
  });

  test('a signed out admin always goes to the login screen', () {
    expect(authRedirect(signedIn: false, location: AppRoutes.dashboard), AppRoutes.login);
    expect(authRedirect(signedIn: false, location: AppRoutes.inbox), AppRoutes.login);
    expect(authRedirect(signedIn: false, location: AppRoutes.login), isNull);
  });

  test('a signed in admin leaves the login screen and stays on other screens', () {
    expect(authRedirect(signedIn: true, location: AppRoutes.login), AppRoutes.dashboard);
    expect(authRedirect(signedIn: true, location: AppRoutes.settings), isNull);
  });
}
