import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_screen.dart';
import '../panel/admin_panel.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = AuthService();
  late bool _signedIn = _auth.session != null;
  SignInDetails? _signIn;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _auth.changes.listen((state) {
      if (state.event == AuthChangeEvent.signedOut && mounted) {
        setState(() {
          _signIn = null;
          _signedIn = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn) return HomeScreen(auth: _auth, signIn: _signIn);
    return LoginScreen(
      auth: _auth,
      onSignedIn: (details) => setState(() {
        _signIn = details;
        _signedIn = true;
      }),
    );
  }
}
