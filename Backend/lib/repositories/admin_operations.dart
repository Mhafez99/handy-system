abstract class AdminOperations {
  Future<bool> isAdmin(String userId);

  Future<Map<String, Object?>> getOverviewStats({
    DateTime? from,
    DateTime? to,
  });

  Future<List<Map<String, Object?>>> getOverviewDailyTrend({
    DateTime? from,
    DateTime? to,
  });

  Future<List<Map<String, Object?>>> listRecentRequests({
    int limit = 20,
    DateTime? from,
    DateTime? to,
    String? status,
  });

  Future<List<Map<String, Object?>>> listPendingWorkers();

  Future<void> approveWorker(String workerId);

  Future<void> rejectWorker(String workerId);

  Future<List<Map<String, Object?>>> listAreas();

  Future<int> createArea({
    required String governorate,
    required String name,
    int sortOrder = 0,
  });

  Future<void> updateArea({
    required int areaId,
    required String governorate,
    required String name,
    required int sortOrder,
    required bool isActive,
  });

  Future<List<Map<String, Object?>>> listComplaints();

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
  });

  Future<List<Map<String, Object?>>> listUsers({
    String? role,
    String? status,
  });

  Future<void> updateUserStatus({
    required String adminUserId,
    required String userId,
    required String status,
  });

  Future<List<Map<String, Object?>>> listCategories();

  Future<int> createCategory({
    required String name,
    int sortOrder = 0,
  });

  Future<void> updateCategory({
    required int categoryId,
    required String name,
    required int sortOrder,
    required bool isActive,
  });

  Future<List<Map<String, Object?>>> listServices({int? categoryId});

  Future<int> createService({
    required int categoryId,
    required String name,
    required int minPrice,
    required int maxPrice,
  });

  Future<void> updateService({
    required int serviceId,
    required int categoryId,
    required String name,
    required int minPrice,
    required int maxPrice,
    required bool isActive,
  });

  Future<List<Map<String, Object?>>> listReviews({
    String? workerId,
    int? minRating,
    int? maxRating,
    bool includeHidden = true,
    int limit = 50,
  });

  Future<void> updateReviewVisibility({
    required String reviewId,
    required bool isHidden,
  });
}
