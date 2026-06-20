import 'package:handy_app/features/reviews/domain/create_review_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsRepository {
  ReviewsRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  Future<void> submitReview(CreateReviewData data) async {
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
