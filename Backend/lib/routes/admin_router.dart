import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/admin_operations.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildAdminRouter(AdminOperations repository) {
  final router = Router()
    ..get('/overview/stats', (Request request) async {
      final dateRange = _readDateRange(request);
      final stats = await repository.getOverviewStats(
        from: dateRange.$1,
        to: dateRange.$2,
      );
      return jsonOk(stats);
    })
    ..get('/overview/trend', (Request request) async {
      final dateRange = _readDateRange(request);
      final trend = await repository.getOverviewDailyTrend(
        from: dateRange.$1,
        to: dateRange.$2,
      );
      return jsonOk(trend);
    })
    ..get('/requests/recent', (Request request) async {
      final dateRange = _readDateRange(request);
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '');
      final status = request.url.queryParameters['status'];

      final requests = await repository.listRecentRequests(
        limit: limit ?? 20,
        from: dateRange.$1,
        to: dateRange.$2,
        status: status == null || status.isEmpty ? null : status,
      );
      return jsonOk(requests);
    })
    ..get('/workers/pending', (Request request) async {
      final workers = await repository.listPendingWorkers();
      return jsonOk(workers);
    })
    ..post('/workers/<workerId>/approve', (
      Request request,
      String workerId,
    ) async {
      await repository.approveWorker(workerId);
      return jsonOk({'ok': true});
    })
    ..post('/workers/<workerId>/reject', (
      Request request,
      String workerId,
    ) async {
      await repository.rejectWorker(workerId);
      return jsonOk({'ok': true});
    })
    ..get('/areas', (Request request) async {
      final areas = await repository.listAreas();
      return jsonOk(areas);
    })
    ..post('/areas', (Request request) async {
      final body = await readJsonBody(request);
      final id = await repository.createArea(
        governorate: body['governorate']?.toString() ?? '',
        name: body['name']?.toString() ?? '',
        sortOrder: _readInt(body['sort_order'], defaultValue: 0),
      );
      return jsonOk({'id': id}, statusCode: 201);
    })
    ..patch('/areas/<areaId>', (Request request, String areaId) async {
      final parsedAreaId = int.tryParse(areaId);
      if (parsedAreaId == null) {
        return jsonError(400, 'Invalid area id');
      }

      final body = await readJsonBody(request);
      await repository.updateArea(
        areaId: parsedAreaId,
        governorate: body['governorate']?.toString() ?? '',
        name: body['name']?.toString() ?? '',
        sortOrder: _readInt(body['sort_order'], defaultValue: 0),
        isActive: body['is_active'] == true,
      );
      return jsonOk({'ok': true});
    })
    ..get('/complaints', (Request request) async {
      final complaints = await repository.listComplaints();
      return jsonOk(complaints);
    })
    ..patch('/complaints/<complaintId>', (
      Request request,
      String complaintId,
    ) async {
      final body = await readJsonBody(request);
      final status = body['status']?.toString() ?? '';
      await repository.updateComplaintStatus(
        complaintId: complaintId,
        status: status,
      );
      return jsonOk({'ok': true});
    })
    ..get('/users', (Request request) async {
      final role = request.url.queryParameters['role'];
      final status = request.url.queryParameters['status'];
      final users = await repository.listUsers(
        role: role == null || role.isEmpty ? null : role,
        status: status == null || status.isEmpty ? null : status,
      );
      return jsonOk(users);
    })
    ..patch('/users/<userId>/status', (Request request, String userId) async {
      final adminUserId = readUserId(request);
      if (adminUserId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final status = body['status']?.toString() ?? '';
      await repository.updateUserStatus(
        adminUserId: adminUserId,
        userId: userId,
        status: status,
      );
      return jsonOk({'ok': true});
    })
    ..get('/categories', (Request request) async {
      final categories = await repository.listCategories();
      return jsonOk(categories);
    })
    ..post('/categories', (Request request) async {
      final body = await readJsonBody(request);
      final id = await repository.createCategory(
        name: body['name']?.toString() ?? '',
        sortOrder: _readInt(body['sort_order'], defaultValue: 0),
      );
      return jsonOk({'id': id}, statusCode: 201);
    })
    ..patch('/categories/<categoryId>', (
      Request request,
      String categoryId,
    ) async {
      final parsedCategoryId = int.tryParse(categoryId);
      if (parsedCategoryId == null) {
        return jsonError(400, 'Invalid category id');
      }

      final body = await readJsonBody(request);
      await repository.updateCategory(
        categoryId: parsedCategoryId,
        name: body['name']?.toString() ?? '',
        sortOrder: _readInt(body['sort_order'], defaultValue: 0),
        isActive: body['is_active'] == true,
      );
      return jsonOk({'ok': true});
    })
    ..get('/services', (Request request) async {
      final categoryId = int.tryParse(
        request.url.queryParameters['category_id'] ?? '',
      );
      final services = await repository.listServices(categoryId: categoryId);
      return jsonOk(services);
    })
    ..post('/services', (Request request) async {
      final body = await readJsonBody(request);
      final categoryId = _readInt(body['category_id']);
      final id = await repository.createService(
        categoryId: categoryId,
        name: body['name']?.toString() ?? '',
        minPrice: _readInt(body['min_price']),
        maxPrice: _readInt(body['max_price']),
      );
      return jsonOk({'id': id}, statusCode: 201);
    })
    ..patch('/services/<serviceId>', (Request request, String serviceId) async {
      final parsedServiceId = int.tryParse(serviceId);
      if (parsedServiceId == null) {
        return jsonError(400, 'Invalid service id');
      }

      final body = await readJsonBody(request);
      await repository.updateService(
        serviceId: parsedServiceId,
        categoryId: _readInt(body['category_id']),
        name: body['name']?.toString() ?? '',
        minPrice: _readInt(body['min_price']),
        maxPrice: _readInt(body['max_price']),
        isActive: body['is_active'] == true,
      );
      return jsonOk({'ok': true});
    })
    ..get('/reviews', (Request request) async {
      final query = request.url.queryParameters;
      final workerId = query['worker_id'];
      final minRating = int.tryParse(query['min_rating'] ?? '');
      final maxRating = int.tryParse(query['max_rating'] ?? '');
      final includeHidden = query['include_hidden'] != 'false';
      final limit = int.tryParse(query['limit'] ?? '') ?? 50;

      final reviews = await repository.listReviews(
        workerId: workerId == null || workerId.isEmpty ? null : workerId,
        minRating: minRating,
        maxRating: maxRating,
        includeHidden: includeHidden,
        limit: limit,
      );
      return jsonOk(reviews);
    })
    ..patch('/reviews/<reviewId>', (Request request, String reviewId) async {
      final body = await readJsonBody(request);
      await repository.updateReviewVisibility(
        reviewId: reviewId,
        isHidden: body['is_hidden'] == true,
      );
      return jsonOk({'ok': true});
    });

  return router.call;
}

(DateTime?, DateTime?) _readDateRange(Request request) {
  return (
    _parseDateTime(request.url.queryParameters['from']),
    _parseDateTime(request.url.queryParameters['to']),
  );
}

DateTime? _parseDateTime(String? rawValue) {
  if (rawValue == null || rawValue.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(rawValue.trim())?.toUtc();
}

int _readInt(Object? value, {int? defaultValue}) {
  if (value == null) {
    if (defaultValue != null) {
      return defaultValue;
    }
    throw const FormatException('Integer value is required');
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.parse(value.toString());
}
