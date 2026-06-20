import 'package:handy_app/features/auth/domain/registration_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  Future<bool> signUp(RegistrationData data) async {
    final response = await _client.auth.signUp(
      email: data.email.trim(),
      password: data.password,
      data: data.toMetadata(),
    );

    return response.session == null;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<Map<String, dynamic>> loadCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    return _client.from('profiles').select().eq('id', user.id).single();
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
