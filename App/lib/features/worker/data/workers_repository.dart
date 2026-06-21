import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/workers_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/features/worker/domain/worker_public_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkersRepository {
  WorkersRepository({SupabaseClient? client, HandyApi? handyApi, WorkersApi? workersApi})
    : _clientOverride = client,
      _handyApi = handyApi,
      _workersApi = workersApi;

  final SupabaseClient? _clientOverride;
  final HandyApi? _handyApi;
  final WorkersApi? _workersApi;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  WorkersApi get _workers {
    return _workersApi ?? (_handyApi ?? HandyApi()).workers;
  }

  Future<WorkerPublicDetails> loadWorkerPublicDetails(String workerId) async {
    if (BackendConfig.isApiConfigured) {
      return _workers.loadWorkerPublicDetails(workerId);
    }

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
