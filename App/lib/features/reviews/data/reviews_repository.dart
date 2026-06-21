import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/requests_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/features/reviews/domain/create_review_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsRepository {
  ReviewsRepository({SupabaseClient? client, HandyApi? handyApi, RequestsApi? requestsApi})
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

  Future<void> submitReview(CreateReviewData data) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.submitReview(
        requestId: data.requestId,
        rating: data.rating,
        comment: data.comment,
      );
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>(
      'submit_service_review',
      params: {
        'p_request_id': data.requestId,
        'p_rating': data.rating,
        'p_comment': data.comment.trim(),
      },
    );
  }
}
