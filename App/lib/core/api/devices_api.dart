import 'package:handy_app/core/api/api_client.dart';

class DevicesApi {
  DevicesApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<void> registerToken({
    required String token,
    required String platform,
  }) {
    return _client.putVoid(
      '/v1/devices/token',
      body: {
        'token': token,
        'platform': platform,
      },
    );
  }

  Future<void> unregisterToken(String token) {
    return _client.deleteVoid(
      '/v1/devices/token',
      body: {'token': token},
    );
  }
}
