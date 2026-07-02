import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/profile_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/core/push/push_notification_service.dart';
import 'package:handy_app/features/auth/domain/registration_data.dart';
import 'package:handy_app/features/auth/domain/update_profile_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client, HandyApi? handyApi, ProfileApi? profileApi})
    : _clientOverride = client,
      _handyApi = handyApi,
      _profileApi = profileApi;

  final SupabaseClient? _clientOverride;
  final HandyApi? _handyApi;
  final ProfileApi? _profileApi;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  ProfileApi get _profile {
    return _profileApi ?? (_handyApi ?? HandyApi()).profile;
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

  Future<void> requestPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<Map<String, dynamic>> loadCurrentProfile() async {
    if (BackendConfig.isApiConfigured) {
      return _profile.loadProfile();
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    return _client.from('profiles').select().eq('id', user.id).single();
  }

  Future<Map<String, dynamic>?> loadWorkerProfile() async {
    if (BackendConfig.isApiConfigured) {
      final profile = await _profile.loadProfile();
      final worker = profile['worker'];
      return worker is Map ? Map<String, dynamic>.from(worker) : null;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final row = await _client
        .from('worker_profiles')
        .select('profession, years_experience, bio, approval_status')
        .eq('user_id', user.id)
        .maybeSingle();

    return row;
  }

  String? get currentUserEmail => _client.auth.currentUser?.email;

  Future<void> updateProfile(UpdateProfileData data) async {
    if (BackendConfig.isApiConfigured) {
      await _profile.updateProfile(data);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client
        .from('profiles')
        .update({
          'full_name': data.fullName.trim(),
          'phone': data.phone.trim(),
          'governorate': data.governorate.trim(),
          'area': data.area.trim(),
          'area_id': data.areaId,
          'address': data.address.trim(),
        })
        .eq('id', user.id);

    if (data.includesWorkerFields) {
      await _client
          .from('worker_profiles')
          .update({
            'profession': data.profession!.trim(),
            'years_experience': data.yearsExperience,
            'bio': data.bio!.trim(),
          })
          .eq('user_id', user.id);
    }
  }

  Future<void> signOut() async {
    await PushNotificationService.instance.unregisterCurrentToken();
    await _client.auth.signOut();
  }
}
