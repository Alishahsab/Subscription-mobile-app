import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/sync/sync_service.dart';
import '../../notifications/push_service.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authControllerProvider = ChangeNotifierProvider((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref.read(syncProvider));
});

class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._sync) : signedIn = _repository.session != null {
    _subscription = _repository.changes.listen((state) {
      if (state.event != AuthChangeEvent.signedOut) return;
      signedIn = false;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  final SyncService _sync;
  late final StreamSubscription<AuthState> _subscription;
  bool signedIn;

  void onSignedIn() {
    signedIn = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await PushService.instance.unregisterDevice();
    await _sync.stop(removeCopy: true);
    await _repository.signOut();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
