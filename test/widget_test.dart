import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_store_admin/features/auth/auth_service.dart';
import 'package:premium_store_admin/features/auth/login_screen.dart';

void main() {
  testWidgets('asks for email and password before signing in', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen(auth: AuthService(), onSignedIn: (_) {})));

    expect(find.text('Premium Store'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Please enter your email and password.'), findsOneWidget);
  });
}
