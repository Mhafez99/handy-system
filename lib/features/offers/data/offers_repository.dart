import 'package:handy_app/features/offers/domain/create_offer_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OffersRepository {
  OffersRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  Future<void> createOffer(CreateOfferData data) async {
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
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>('accept_offer', params: {'p_offer_id': offerId});
  }
}
