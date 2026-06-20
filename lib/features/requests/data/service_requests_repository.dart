import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/create_service_request_data.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';
import 'package:handy_app/features/requests/domain/service_request_details.dart';
import 'package:handy_app/features/requests/domain/service_category.dart';
import 'package:handy_app/features/requests/domain/service_item.dart';
import 'package:handy_app/features/reviews/domain/worker_rating_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRequestsRepository {
  ServiceRequestsRepository({SupabaseClient? client})
    : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  Future<List<ServiceCategory>> loadCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, name')
        .order('sort_order');

    return rows
        .map((row) => ServiceCategory.fromJson(row))
        .toList(growable: false);
  }

  Future<List<ServiceItem>> loadServices(int categoryId) async {
    final rows = await _client
        .from('services')
        .select('id, category_id, name, min_price, max_price')
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('name');

    return rows.map((row) => ServiceItem.fromJson(row)).toList(growable: false);
  }

  Future<List<CustomerRequest>> loadCustomerRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final rows = await _client
        .from('service_requests')
        .select(
          'id, area, status, created_at, services(name, categories(name)), offers(id)',
        )
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);

    return rows
        .map((row) => CustomerRequest.fromJson(row))
        .toList(growable: false);
  }

  Future<ServiceRequestDetails> loadCustomerRequestDetails(
    String requestId,
  ) async {
    final row = await _client
        .from('service_requests')
        .select(
          'id, description, governorate, area, address, preferred_time, status, created_at, '
          'services(name, min_price, max_price, categories(name)), '
          'offers(id, worker_id, price, arrival_time, note, status, created_at, worker:profiles!offers_worker_id_fkey(full_name, phone)), '
          'service_reviews(id, rating, comment, created_at)',
        )
        .eq('id', requestId)
        .single();

    final details = ServiceRequestDetails.fromJson(row);
    final workerIds = details.offers
        .map((offer) => offer.workerId)
        .where((workerId) => workerId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (workerIds.isEmpty) {
      return details;
    }

    final summaries = await _loadWorkerRatingSummaries(workerIds);

    return details.withOffers(
      details.offers
          .map((offer) {
            final summary = summaries[offer.workerId];

            return offer.withRatingSummary(
              averageRating: summary?.averageRating,
              reviewCount: summary?.reviewCount ?? 0,
            );
          })
          .toList(growable: false),
    );
  }

  Future<Map<String, WorkerRatingSummary>> _loadWorkerRatingSummaries(
    List<String> workerIds,
  ) async {
    final rows = await _client.rpc<List<dynamic>>(
      'worker_rating_summary',
      params: {'p_worker_ids': workerIds},
    );

    final summaries = rows
        .map((row) => WorkerRatingSummary.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);

    return {for (final summary in summaries) summary.workerId: summary};
  }

  Future<List<AvailableWorkerRequest>> loadAvailableWorkerRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final rows = await _client
        .from('service_requests')
        .select(
          'id, description, area, preferred_time, status, created_at, '
          'services(name, min_price, max_price, categories(name))',
        )
        .inFilter('status', ['new', 'offered'])
        .order('created_at', ascending: false);

    return rows
        .map((row) => AvailableWorkerRequest.fromJson(row))
        .toList(growable: false);
  }

  Future<List<AcceptedWorkerRequest>> loadAcceptedWorkerRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final rows = await _client
        .from('service_requests')
        .select(
          'id, description, governorate, area, address, preferred_time, status, created_at, '
          'services(name, categories(name)), '
          'customer:profiles!service_requests_customer_id_fkey(full_name, phone, address), '
          'offers!inner(price, arrival_time, status, worker_id), '
          'service_reviews(id, rating, comment, created_at)',
        )
        .inFilter('status', ['accepted', 'in_progress', 'completed'])
        .eq('offers.worker_id', user.id)
        .eq('offers.status', 'accepted')
        .order('created_at', ascending: false);

    return rows
        .map((row) => AcceptedWorkerRequest.fromJson(row))
        .toList(growable: false);
  }

  Future<void> startWork(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>('start_work', params: {'p_request_id': requestId});
  }

  Future<void> completeRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>(
      'complete_request',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> createRequest(CreateServiceRequestData data) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.from('service_requests').insert({
      'customer_id': user.id,
      'category_id': data.categoryId,
      'service_id': data.serviceId,
      'description': data.description.trim(),
      'governorate': data.governorate.trim(),
      'area': data.area.trim(),
      'address': data.address.trim(),
      'preferred_time': data.preferredTime.trim(),
    });
  }
}
