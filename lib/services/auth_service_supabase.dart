import 'package:supabase_flutter/supabase_flutter.dart';

class AuthServiceSupabase {
  final _client = Supabase.instance.client;

  Future<AuthResponse> login(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> register(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();
}
