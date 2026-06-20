import 'package:handy_app/features/worker/domain/worker_public_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkersRepository {
  WorkersRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  Future<WorkerPublicDetails> loadWorkerPublicDetails(String workerId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final row = await _client.rpc<Map<String, dynamic>>(
      'worker_public_details',
      params: {'p_worker_id': workerId},
    );

    return WorkerPublicDetails.fromJson(row);
  }
}
