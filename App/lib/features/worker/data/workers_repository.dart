import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/workers_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/features/worker/domain/worker_earnings.dart';
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

  Future<WorkerEarnings> loadMyEarnings() async {
    if (BackendConfig.isApiConfigured) {
      return _workers.loadMyEarnings();
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final rows = await _client
        .from('platform_commissions')
        .select(
          'request_id, gross_amount, commission_rate, commission_amount, net_amount, created_at, '
          'service_requests(services(name, categories(name)))',
        )
        .eq('worker_id', user.id)
        .order('created_at', ascending: false)
        .limit(30);

    var totalGross = 0;
    var totalCommission = 0;
    var totalNet = 0;
    final recent = <WorkerEarningItem>[];

    for (final row in rows) {
      final gross = (row['gross_amount'] as num?)?.toInt() ?? 0;
      final commission = (row['commission_amount'] as num?)?.toInt() ?? 0;
      final net = (row['net_amount'] as num?)?.toInt() ?? 0;
      totalGross += gross;
      totalCommission += commission;
      totalNet += net;

      final request = row['service_requests'] as Map<String, dynamic>?;
      final service = request?['services'] as Map<String, dynamic>?;
      final category = service?['categories'] as Map<String, dynamic>?;

      recent.add(
        WorkerEarningItem(
          requestId: row['request_id'] as String? ?? '',
          serviceName: service?['name'] as String? ?? 'خدمة',
          categoryName: category?['name'] as String? ?? '',
          grossAmount: gross,
          commissionRate: (row['commission_rate'] as num?)?.toDouble() ?? 0,
          commissionAmount: commission,
          netAmount: net,
          createdAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
        ),
      );
    }

    return WorkerEarnings(
      jobsCount: recent.length,
      totalGross: totalGross,
      totalCommission: totalCommission,
      totalNet: totalNet,
      recent: recent,
    );
  }
}
