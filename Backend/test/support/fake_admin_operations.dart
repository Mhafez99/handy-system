import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:handy_backend/repositories/admin_operations.dart';

class FakeAdminOperations implements AdminOperations {
  FakeAdminOperations({this.adminUserIds = const {testAdminUserId}});

  static const testAdminUserId = '11111111-1111-1111-1111-111111111111';

  final Set<String> adminUserIds;
  final List<String> calls = [];

  @override
  Future<bool> isAdmin(String userId) async {
    calls.add('isAdmin:$userId');
    return adminUserIds.contains(userId);
  }

  @override
  Future<Map<String, Object?>> getOverviewStats({
    DateTime? from,
    DateTime? to,
  }) async {
    calls.add('getOverviewStats');
    return {
      'total_requests': 10,
      'requests_today': 2,
      'completed_requests': 5,
      'active_requests': 3,
      'open_complaints': 1,
      'pending_workers': 2,
      'total_customers': 20,
      'active_workers': 8,
      'total_offers': 15,
      'offers_in_period': 4,
      'status_counts': {'new': 1},
      'is_filtered': from != null || to != null,
    };
  }

  @override
  Future<List<Map<String, Object?>>> getOverviewDailyTrend({
    DateTime? from,
    DateTime? to,
  }) async {
    calls.add('getOverviewDailyTrend');
    return [
      {'day': '2026-06-01', 'total': 3, 'completed': 1},
    ];
  }

  @override
  Future<List<Map<String, Object?>>> listRecentRequests({
    int limit = 20,
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    calls.add('listRecentRequests');
    return [
      {
        'id': 'request-1',
        'status': status ?? 'new',
        'created_at': '2026-06-01T10:00:00.000Z',
        'area': 'المعادي',
        'governorate': 'القاهرة',
        'service_name': 'سباكة',
        'category_name': 'سباكة',
        'customer_name': 'عميل',
        'worker_name': '',
        'offer_count': 0,
        'final_price': null,
        'payment_method': null,
      },
    ];
  }

  @override
  Future<List<Map<String, Object?>>> listPendingWorkers() async {
    calls.add('listPendingWorkers');
    return [
      {
        'user_id': 'worker-1',
        'full_name': 'صنايعي',
        'phone': '01000000000',
        'governorate': 'القاهرة',
        'area': 'المعادي',
        'address': 'عنوان',
        'profession': 'سباكة',
        'years_experience': 5,
        'bio': 'bio',
        'created_at': '2026-06-01T10:00:00.000Z',
      },
    ];
  }

  @override
  Future<void> approveWorker(String workerId) async {
    calls.add('approveWorker:$workerId');
  }

  @override
  Future<void> rejectWorker(String workerId) async {
    calls.add('rejectWorker:$workerId');
  }

  @override
  Future<List<Map<String, Object?>>> listAreas() async {
    calls.add('listAreas');
    return [
      {
        'id': 1,
        'governorate': 'القاهرة',
        'name': 'المعادي',
        'sort_order': 1,
        'is_active': true,
        'created_at': '2026-06-01T10:00:00.000Z',
      },
    ];
  }

  @override
  Future<int> createArea({
    required String governorate,
    required String name,
    int sortOrder = 0,
  }) async {
    calls.add('createArea');
    return 2;
  }

  @override
  Future<void> updateArea({
    required int areaId,
    required String governorate,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    calls.add('updateArea:$areaId');
  }

  @override
  Future<List<Map<String, Object?>>> listComplaints() async {
    calls.add('listComplaints');
    return [
      {
        'id': 'complaint-1',
        'request_id': 'request-1',
        'category': 'poor_quality',
        'description': 'وصف الشكوى',
        'status': 'open',
        'created_at': '2026-06-01T10:00:00.000Z',
        'customer_name': 'عميل',
        'customer_phone': '01000000000',
        'worker_name': 'صنايعي',
        'worker_phone': '01000000001',
        'service_name': 'سباكة',
        'area': 'المعادي',
      },
    ];
  }

  @override
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
  }) async {
    calls.add('updateComplaintStatus:$complaintId');
  }

  @override
  Future<List<Map<String, Object?>>> listUsers({
    String? role,
    String? status,
  }) async {
    calls.add('listUsers');
    return [
      {
        'user_id': 'user-1',
        'full_name': 'مستخدم',
        'phone': '01000000000',
        'role': role ?? 'customer',
        'governorate': 'القاهرة',
        'area': 'المعادي',
        'status': status ?? 'active',
        'profession': '',
        'approval_status': '',
        'created_at': '2026-06-01T10:00:00.000Z',
      },
    ];
  }

  @override
  Future<void> updateUserStatus({
    required String adminUserId,
    required String userId,
    required String status,
  }) async {
    calls.add('updateUserStatus:$userId');
  }

  @override
  Future<List<Map<String, Object?>>> listCategories() async {
    calls.add('listCategories');
    return [
      {
        'id': 1,
        'name': 'سباكة',
        'sort_order': 1,
        'is_active': true,
        'service_count': 2,
        'active_service_count': 2,
        'created_at': '2026-06-01T10:00:00.000Z',
      },
    ];
  }

  @override
  Future<int> createCategory({
    required String name,
    int sortOrder = 0,
  }) async {
    calls.add('createCategory');
    return 3;
  }

  @override
  Future<void> updateCategory({
    required int categoryId,
    required String name,
    required int sortOrder,
    required bool isActive,
  }) async {
    calls.add('updateCategory:$categoryId');
  }

  @override
  Future<List<Map<String, Object?>>> listServices({int? categoryId}) async {
    calls.add('listServices');
    return [
      {
        'id': 1,
        'category_id': categoryId ?? 1,
        'category_name': 'سباكة',
        'name': 'تسليك مجاري',
        'min_price': 100,
        'max_price': 300,
        'is_active': true,
        'created_at': '2026-06-01T10:00:00.000Z',
      },
    ];
  }

  @override
  Future<int> createService({
    required int categoryId,
    required String name,
    required int minPrice,
    required int maxPrice,
  }) async {
    calls.add('createService');
    return 4;
  }

  @override
  Future<void> updateService({
    required int serviceId,
    required int categoryId,
    required String name,
    required int minPrice,
    required int maxPrice,
    required bool isActive,
  }) async {
    calls.add('updateService:$serviceId');
    if (minPrice > maxPrice) {
      throw const RequestActionException('Invalid maximum price');
    }
  }

  @override
  Future<List<Map<String, Object?>>> listReviews({
    String? workerId,
    int? minRating,
    int? maxRating,
    bool includeHidden = true,
    int limit = 50,
  }) async {
    calls.add('listReviews');
    return [
      {
        'id': 'review-1',
        'request_id': 'request-1',
        'worker_id': workerId ?? 'worker-1',
        'worker_name': 'أحمد الصنايعي',
        'worker_phone': '01000000000',
        'customer_id': 'customer-1',
        'customer_name': 'محمد العميل',
        'customer_phone': '01100000000',
        'rating': 5,
        'comment': 'خدمة ممتازة',
        'is_hidden': false,
        'created_at': '2026-06-01T10:00:00.000Z',
        'service_name': 'تسليك صرف',
        'area': 'مدينة نصر',
      },
    ];
  }

  @override
  Future<void> updateReviewVisibility({
    required String reviewId,
    required bool isHidden,
  }) async {
    calls.add('updateReviewVisibility:$reviewId:$isHidden');
  }
}
