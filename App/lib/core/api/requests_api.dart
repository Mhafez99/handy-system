import 'package:handy_app/core/api/api_client.dart';
import 'package:handy_app/features/offers/domain/create_offer_data.dart';
import 'package:handy_app/features/requests/domain/create_service_request_data.dart';
import 'package:handy_app/features/requests/domain/request_image.dart';
import 'package:handy_app/features/requests/domain/request_image_upload_slot.dart';

class RequestsApi {
  RequestsApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> loadCustomerRequests() {
    return _client.getList('/v1/requests/mine');
  }

  Future<List<Map<String, dynamic>>> loadAvailableWorkerRequests() {
    return _client.getList('/v1/requests/available');
  }

  Future<List<Map<String, dynamic>>> loadActiveWorkerRequests() {
    return _client.getList('/v1/requests/worker/active');
  }

  Future<List<Map<String, dynamic>>> loadCompletedWorkerRequests() {
    return _client.getList('/v1/requests/worker/completed');
  }

  Future<Map<String, dynamic>> loadRequestDetails(String requestId) {
    return _client.getObject('/v1/requests/$requestId');
  }

  Future<String> createRequest(CreateServiceRequestData data) async {
    final response = await _client.postObject(
      '/v1/requests',
      body: {
        'category_id': data.categoryId,
        'service_id': data.serviceId,
        'description': data.description.trim(),
        'governorate': data.governorate.trim(),
        'area': data.area.trim(),
        'area_id': data.areaId,
        'address': data.address.trim(),
        'preferred_time': data.preferredTime.trim(),
      },
    );

    return response['id'] as String;
  }

  Future<void> createOffer({
    required String requestId,
    required CreateOfferData data,
  }) {
    return _client.postVoid(
      '/v1/requests/$requestId/offers',
      body: {
        'price': data.price,
        'arrival_time': data.arrivalTime.trim(),
        'note': data.note.trim(),
      },
    );
  }

  Future<void> acceptOffer(String offerId) {
    return _client.postVoid('/v1/requests/offers/$offerId/accept');
  }

  Future<void> markOnTheWay(String requestId) {
    return _client.postVoid('/v1/requests/$requestId/on-the-way');
  }

  Future<void> startWork(String requestId) {
    return _client.postVoid('/v1/requests/$requestId/start');
  }

  Future<void> completeRequestByWorker({
    required String requestId,
    required String completionCode,
    required int finalPrice,
  }) {
    return _client.postVoid(
      '/v1/requests/$requestId/complete',
      body: {
        'code': completionCode.trim(),
        'final_price': finalPrice,
      },
    );
  }

  Future<void> cancelRequest(String requestId) {
    return _client.postVoid('/v1/requests/$requestId/cancel');
  }

  Future<void> submitComplaint({
    required String requestId,
    required String category,
    required String description,
  }) {
    return _client.postVoid(
      '/v1/requests/$requestId/complaints',
      body: {
        'category': category,
        'description': description.trim(),
      },
    );
  }

  Future<void> submitReview({
    required String requestId,
    required int rating,
    required String comment,
  }) {
    return _client.postVoid(
      '/v1/requests/$requestId/reviews',
      body: {
        'rating': rating,
        'comment': comment.trim(),
      },
    );
  }

  Future<List<RequestImage>> loadRequestImages(String requestId) async {
    final rows = await _client.getList('/v1/requests/$requestId/images');
    return rows.map(RequestImage.fromJson).toList(growable: false);
  }

  Future<List<RequestImageUploadSlot>> createRequestImageUploadUrls({
    required String requestId,
    required List<Map<String, dynamic>> images,
  }) async {
    final rows = await _client.postList(
      '/v1/requests/$requestId/images/upload-urls',
      body: {'images': images},
    );

    return rows
        .map(RequestImageUploadSlot.fromJson)
        .toList(growable: false);
  }
}
