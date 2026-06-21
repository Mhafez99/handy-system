import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/requests_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/features/complaints/domain/create_complaint_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintsRepository {
  ComplaintsRepository({SupabaseClient? client, HandyApi? handyApi, RequestsApi? requestsApi})
    : _clientOverride = client,
      _handyApi = handyApi,
      _requestsApi = requestsApi;

  final SupabaseClient? _clientOverride;
  final HandyApi? _handyApi;
  final RequestsApi? _requestsApi;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  RequestsApi get _requests {
    return _requestsApi ?? (_handyApi ?? HandyApi()).requests;
  }

  Future<void> submitComplaint(CreateComplaintData data) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.submitComplaint(
        requestId: data.requestId,
        category: data.category,
        description: data.description,
      );
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>(
      'submit_service_complaint',
      params: {
        'p_request_id': data.requestId,
        'p_category': data.category,
        'p_description': data.description.trim(),
      },
    );
  }
}
