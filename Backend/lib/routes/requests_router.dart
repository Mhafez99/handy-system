import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/requests_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildRequestsRouter(RequestsRepository repository) {
  final router = Router()
    ..get('/mine', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final requests = await repository.listCustomerRequests(userId);
      return jsonOk(requests);
    })
    ..get('/available', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final requests = await repository.listAvailableWorkerRequests(userId);
      return jsonOk(requests);
    })
    ..get('/worker/active', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final requests = await repository.listActiveWorkerRequests(userId);
      return jsonOk(requests);
    })
    ..get('/worker/completed', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final requests = await repository.listCompletedWorkerRequests(userId);
      return jsonOk(requests);
    })
    ..post('/', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final categoryId = _readRequiredInt(body['category_id'], 'Category is required');
      final serviceId = _readRequiredInt(body['service_id'], 'Service is required');
      final areaId = _readRequiredInt(body['area_id'], 'Area is required');
      final description = body['description'];
      final governorate = body['governorate'];
      final area = body['area'];
      final address = body['address'];
      final preferredTime = body['preferred_time'];

      if (description is! String ||
          governorate is! String ||
          area is! String ||
          address is! String ||
          preferredTime is! String) {
        return jsonError(400, 'Invalid request payload');
      }

      final requestId = await repository.createRequest(
        userId: userId,
        categoryId: categoryId,
        serviceId: serviceId,
        description: description,
        governorate: governorate,
        area: area,
        areaId: areaId,
        address: address,
        preferredTime: preferredTime,
      );

      return jsonOk({'id': requestId}, statusCode: 201);
    })
    ..get('/<requestId>', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final details = await repository.getCustomerRequestDetails(
        userId,
        requestId,
      );
      return jsonOk(details);
    })
    ..get('/<requestId>/images', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final images = await repository.listRequestImages(userId, requestId);
      return jsonOk(images);
    })
    ..post('/<requestId>/images/upload-urls', (
      Request request,
      String requestId,
    ) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final rawImages = body['images'];

      if (rawImages is! List || rawImages.isEmpty) {
        return jsonError(400, 'images is required');
      }

      final images = rawImages
          .whereType<Map>()
          .map((image) => Map<String, Object?>.from(image))
          .toList(growable: false);

      final uploads = await repository.createRequestImageUploadUrls(
        userId: userId,
        requestId: requestId,
        images: images,
      );

      return jsonOk(uploads, statusCode: 201);
    })
    ..post('/offers/<offerId>/accept', (Request request, String offerId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      await repository.acceptOffer(userId, offerId);
      return jsonOk({'ok': true});
    })
    ..post('/<requestId>/offers', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final price = _readRequiredInt(body['price'], 'Price is required');
      final arrivalTime = body['arrival_time'];
      final note = body['note'];

      if (arrivalTime is! String) {
        return jsonError(400, 'Arrival time is required');
      }

      await repository.createOffer(
        userId: userId,
        requestId: requestId,
        price: price,
        arrivalTime: arrivalTime,
        note: note is String ? note : '',
      );
      return jsonOk({'ok': true}, statusCode: 201);
    })
    ..post('/<requestId>/cancel', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      await repository.cancelRequest(userId, requestId);
      return jsonOk({'ok': true});
    })
    ..post('/<requestId>/complaints', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final category = body['category'];
      final description = body['description'];

      if (category is! String || description is! String) {
        return jsonError(400, 'Invalid complaint payload');
      }

      await repository.submitServiceComplaint(
        userId: userId,
        requestId: requestId,
        category: category,
        description: description,
      );
      return jsonOk({'ok': true}, statusCode: 201);
    })
    ..post('/<requestId>/reviews', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final rating = _readRequiredInt(body['rating'], 'Rating is required');
      final comment = body['comment'];

      await repository.submitServiceReview(
        userId: userId,
        requestId: requestId,
        rating: rating,
        comment: comment is String ? comment : '',
      );
      return jsonOk({'ok': true}, statusCode: 201);
    })
    ..post('/<requestId>/on-the-way', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      await repository.markOnTheWay(userId, requestId);
      return jsonOk({'ok': true});
    })
    ..post('/<requestId>/start', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      await repository.startWork(userId, requestId);
      return jsonOk({'ok': true});
    })
    ..post('/<requestId>/complete', (Request request, String requestId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final code = body['code'];
      final finalPrice = body['final_price'];

      if (code is! String) {
        return jsonError(400, 'Completion code is required');
      }

      final parsedPrice = switch (finalPrice) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };

      if (parsedPrice == null) {
        return jsonError(400, 'Final price is required');
      }

      await repository.completeRequestByWorker(
        userId: userId,
        requestId: requestId,
        code: code,
        finalPrice: parsedPrice,
      );
      return jsonOk({'ok': true});
    });

  return router.call;
}

int _readRequiredInt(Object? value, String errorMessage) {
  final parsed = switch (value) {
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };

  if (parsed == null) {
    throw FormatException(errorMessage);
  }

  return parsed;
}
