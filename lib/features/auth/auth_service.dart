import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Session? get session => _client.auth.currentSession;

  Stream<AuthState> get changes => _client.auth.onAuthStateChange;

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(email: email.trim().toLowerCase(), password: password);
      final userId = response.user?.id;
      if (userId == null) return 'Incorrect email or password.';

      final admin = await _client.from('admins').select('user_id').eq('user_id', userId).maybeSingle();
      if (admin == null) {
        await _client.auth.signOut();
        return 'This account does not have admin access.';
      }
      return null;
    } on AuthException {
      return 'Incorrect email or password.';
    } catch (_) {
      return 'No internet connection. Please try again.';
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
