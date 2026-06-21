import 'package:handy_app/core/api/catalog_api.dart';
import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/api/requests_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/create_service_request_data.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';
import 'package:handy_app/features/requests/domain/request_image.dart';
import 'package:handy_app/features/requests/domain/service_request_details.dart';
import 'package:handy_app/features/requests/domain/service_category.dart';
import 'package:handy_app/features/requests/domain/service_item.dart';
import 'package:handy_app/features/reviews/domain/worker_rating_summary.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRequestsRepository {
  static const requestImagesBucket = 'request-images';
  ServiceRequestsRepository({
    SupabaseClient? client,
    HandyApi? handyApi,
    CatalogApi? catalogApi,
    RequestsApi? requestsApi,
  }) : _clientOverride = client,
       _handyApi = handyApi,
       _catalogApi = catalogApi,
       _requestsApi = requestsApi;

  final SupabaseClient? _clientOverride;
  final HandyApi? _handyApi;
  final CatalogApi? _catalogApi;
  final RequestsApi? _requestsApi;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  HandyApi get _api {
    return _handyApi ?? HandyApi();
  }

  CatalogApi get _catalog {
    return _catalogApi ?? _api.catalog;
  }

  RequestsApi get _requests {
    return _requestsApi ?? _api.requests;
  }

  Future<List<ServiceCategory>> loadCategories() async {
    if (BackendConfig.isApiConfigured) {
      final rows = await _catalog.loadCategories();
      return rows
          .map((row) => ServiceCategory.fromJson(row))
          .toList(growable: false);
    }

    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .order('sort_order');

    return rows
        .map((row) => ServiceCategory.fromJson(row))
        .toList(growable: false);
  }

  Future<List<ServiceItem>> loadServices(int categoryId) async {
    if (BackendConfig.isApiConfigured) {
      final rows = await _catalog.loadServices(categoryId: categoryId);
      return rows.map((row) => ServiceItem.fromJson(row)).toList(growable: false);
    }

    final rows = await _client
        .from('services')
        .select('id, category_id, name, min_price, max_price')
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('name');

    return rows.map((row) => ServiceItem.fromJson(row)).toList(growable: false);
  }

  Future<List<CustomerRequest>> loadCustomerRequests() async {
    if (BackendConfig.isApiConfigured) {
      final rows = await _requests.loadCustomerRequests();
      return rows
          .map((row) => CustomerRequest.fromJson(row))
          .toList(growable: false);
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final rows = await _client
        .from('service_requests')
        .select(
          'id, area, status, created_at, final_price, payment_method, services(name, categories(name)), offers(id)',
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
    if (BackendConfig.isApiConfigured) {
      final row = await _requests.loadRequestDetails(requestId);
      final details = ServiceRequestDetails.fromJson(row);
      return _enrichRequestDetails(details, requestId);
    }

    final row = await _client
        .from('service_requests')
        .select(
          'id, description, governorate, area, address, preferred_time, status, created_at, '
          'completion_code, final_price, payment_method, '
          'services(name, min_price, max_price, categories(name)), '
          'offers(id, worker_id, price, arrival_time, note, status, created_at, worker:profiles!offers_worker_id_fkey(full_name, phone)), '
          'service_reviews(id, rating, comment, created_at), '
          'service_complaints(id, category, description, status, created_at)',
        )
        .eq('id', requestId)
        .single();

    final details = ServiceRequestDetails.fromJson(row);
    return _enrichRequestDetails(details, requestId);
  }

  Future<ServiceRequestDetails> _enrichRequestDetails(
    ServiceRequestDetails details,
    String requestId,
  ) async {
    final detailsWithImages = details.withImages(
      await loadRequestImages(requestId),
    );
    final workerIds = detailsWithImages.offers
        .map((offer) => offer.workerId)
        .where((workerId) => workerId.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (workerIds.isEmpty) {
      return detailsWithImages;
    }

    final summaries = await _loadWorkerRatingSummaries(workerIds);

    return detailsWithImages.withOffers(
      detailsWithImages.offers
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

  Future<List<RequestImage>> loadRequestImages(String requestId) async {
    if (BackendConfig.isApiConfigured) {
      return _requests.loadRequestImages(requestId);
    }

    final rows = await _client
        .from('request_images')
        .select('id, storage_path, sort_order')
        .eq('request_id', requestId)
        .order('sort_order');

    final images = <RequestImage>[];

    for (final row in rows) {
      final path = row['storage_path'] as String;
      final signedUrl = await _client.storage
          .from(requestImagesBucket)
          .createSignedUrl(path, 3600);

      images.add(
        RequestImage(
          id: row['id'] as String,
          url: signedUrl,
          sortOrder: row['sort_order'] as int? ?? 0,
        ),
      );
    }

    return images;
  }

  Future<Map<String, WorkerRatingSummary>> _loadWorkerRatingSummaries(
    List<String> workerIds,
  ) async {
    if (BackendConfig.isApiConfigured) {
      final summaries = await _api.workers.loadWorkerRatingSummaries(workerIds);
      return {for (final summary in summaries) summary.workerId: summary};
    }

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
    if (BackendConfig.isApiConfigured) {
      final rows = await _requests.loadAvailableWorkerRequests();
      return rows
          .map((row) => AvailableWorkerRequest.fromJson(row))
          .toList(growable: false);
    }

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

  Future<List<AcceptedWorkerRequest>> loadActiveWorkerRequests() async {
    if (BackendConfig.isApiConfigured) {
      final rows = await _requests.loadActiveWorkerRequests();
      return rows
          .map((row) => AcceptedWorkerRequest.fromJson(row))
          .toList(growable: false);
    }

    return _loadWorkerRequests(const ['accepted', 'on_the_way', 'in_progress']);
  }

  Future<List<AcceptedWorkerRequest>> loadCompletedWorkerRequests() async {
    if (BackendConfig.isApiConfigured) {
      final rows = await _requests.loadCompletedWorkerRequests();
      return rows
          .map((row) => AcceptedWorkerRequest.fromJson(row))
          .toList(growable: false);
    }

    return _loadWorkerRequests(const ['completed', 'complaint']);
  }

  Future<List<AcceptedWorkerRequest>> _loadWorkerRequests(
    List<String> statuses,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final rows = await _client
        .from('service_requests')
        .select(
          'id, description, governorate, area, address, preferred_time, status, created_at, '
          'final_price, payment_method, '
          'services(name, categories(name)), '
          'customer:profiles!service_requests_customer_id_fkey(full_name, phone, address), '
          'offers!inner(price, arrival_time, status, worker_id), '
          'service_reviews(id, rating, comment, created_at)',
        )
        .inFilter('status', statuses)
        .eq('offers.worker_id', user.id)
        .eq('offers.status', 'accepted')
        .order('created_at', ascending: false);

    return rows
        .map((row) => AcceptedWorkerRequest.fromJson(row))
        .toList(growable: false);
  }

  Future<void> markOnTheWay(String requestId) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.markOnTheWay(requestId);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>(
      'mark_on_the_way',
      params: {'p_request_id': requestId},
    );
  }

  Future<void> startWork(String requestId) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.startWork(requestId);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>('start_work', params: {'p_request_id': requestId});
  }

  Future<void> completeRequestByWorker({
    required String requestId,
    required String completionCode,
    required int finalPrice,
  }) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.completeRequestByWorker(
        requestId: requestId,
        completionCode: completionCode,
        finalPrice: finalPrice,
      );
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client.rpc<void>(
      'complete_request_by_worker',
      params: {
        'p_request_id': requestId,
        'p_code': completionCode.trim(),
        'p_final_price': finalPrice,
      },
    );
  }

  Future<void> cancelRequest(String requestId) async {
    if (BackendConfig.isApiConfigured) {
      await _requests.cancelRequest(requestId);
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    await _client
        .from('service_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId)
        .eq('customer_id', user.id);
  }

  Future<String> createRequest(CreateServiceRequestData data) async {
    if (BackendConfig.isApiConfigured) {
      return _requests.createRequest(data);
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    final row = await _client
        .from('service_requests')
        .insert({
          'customer_id': user.id,
          'category_id': data.categoryId,
          'service_id': data.serviceId,
          'description': data.description.trim(),
          'governorate': data.governorate.trim(),
          'area': data.area.trim(),
          'area_id': data.areaId,
          'address': data.address.trim(),
          'preferred_time': data.preferredTime.trim(),
        })
        .select('id')
        .single();

    return row['id'] as String;
  }

  Future<void> uploadRequestImages(String requestId, List<XFile> images) async {
    if (BackendConfig.isApiConfigured) {
      final uploads = await _requests.createRequestImageUploadUrls(
        requestId: requestId,
        images: [
          for (var index = 0; index < images.length; index++)
            {
              'content_type': _contentTypeForFile(images[index]),
              'sort_order': index,
            },
        ],
      );

      for (var index = 0; index < uploads.length; index++) {
        final upload = uploads[index];
        final bytes = await images[index].readAsBytes();
        final response = await http.put(
          Uri.parse(upload.uploadUrl),
          headers: {
            'Authorization': 'Bearer ${upload.token}',
            'Content-Type': upload.contentType,
          },
          body: bytes,
        );

        if (response.statusCode >= 400) {
          throw const AuthException('تعذر رفع صورة الطلب.');
        }
      }

      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('لا توجد جلسة مستخدم نشطة.');
    }

    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      final bytes = await image.readAsBytes();
      final extension = _fileExtension(image.path);
      final contentType = _contentTypeForExtension(extension);
      final storagePath =
          '${user.id}/$requestId/${DateTime.now().microsecondsSinceEpoch}_$index$extension';

      await _client.storage.from(requestImagesBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );

      await _client.from('request_images').insert({
        'request_id': requestId,
        'storage_path': storagePath,
        'sort_order': index,
      });
    }
  }

  String _contentTypeForFile(XFile image) {
    return _contentTypeForExtension(_fileExtension(image.path));
  }

  String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }

    final extension = path.substring(dotIndex).toLowerCase();
    if (extension == '.png' || extension == '.webp' || extension == '.jpeg') {
      return extension == '.jpeg' ? '.jpg' : extension;
    }

    return '.jpg';
  }

  String _contentTypeForExtension(String extension) {
    return switch (extension) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
