import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/requests_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/features/offers/domain/create_offer_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OffersRepository {
  OffersRepository({SupabaseClient? client, HandyApi? handyApi, RequestsApi? requestsApi})
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

  Future<void> createOffer(CreateOfferData data) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.createOffer(requestId: data.requestId, data: data);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.from('offers').insert({
      'request_id': data.requestId,
      'worker_id': user.id,
      'price': data.price,
      'arrival_time': data.arrivalTime.trim(),
      'note': data.note.trim().isEmpty ? null : data.note.trim(),
    });
  }

  Future<void> acceptOffer(String offerId) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.acceptOffer(offerId);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>('accept_offer', params: {'p_offer_id': offerId});
  }
}
