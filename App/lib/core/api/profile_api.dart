import 'package:handy_app/core/api/api_client.dart';
import 'package:handy_app/features/auth/domain/update_profile_data.dart';

class ProfileApi {
  ProfileApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Map<String, dynamic>> loadProfile() {
    return _client.getObject('/v1/profile');
  }

  Future<Map<String, dynamic>> updateProfile(UpdateProfileData data) {
    return _client.patchObject(
      '/v1/profile',
      body: {
        'full_name': data.fullName.trim(),
        'phone': data.phone.trim(),
        'governorate': data.governorate.trim(),
        'area': data.area.trim(),
        'area_id': data.areaId,
        'address': data.address.trim(),
        if (data.includesWorkerFields)
          'worker': {
            'profession': data.profession!.trim(),
            'years_experience': data.yearsExperience,
            'bio': data.bio!.trim(),
          },
      },
    );
  }
}
