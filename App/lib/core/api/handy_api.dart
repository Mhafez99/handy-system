import 'package:handy_app/core/api/api_client.dart';
import 'package:handy_app/core/api/catalog_api.dart';
import 'package:handy_app/core/api/devices_api.dart';
import 'package:handy_app/core/api/requests_api.dart';
import 'package:handy_app/core/api/workers_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HandyApi {
  HandyApi({ApiClient? client})
    : _client =
          client ??
          ApiClient(
            baseUrl: BackendConfig.handyApiUrl,
            accessToken: _currentAccessToken(),
          );

  final ApiClient _client;

  static String? _currentAccessToken() {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  CatalogApi get catalog => CatalogApi(client: _client);

  RequestsApi get requests => RequestsApi(client: _client);

  WorkersApi get workers => WorkersApi(client: _client);

  DevicesApi get devices => DevicesApi(client: _client);
}
