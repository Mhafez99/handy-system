import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';

enum WorkerHistoryFilter {
  all,
  reviewed,
  pendingReview,
}

extension WorkerHistoryFilterX on WorkerHistoryFilter {
  String get label {
    return switch (this) {
      WorkerHistoryFilter.all => 'الكل',
      WorkerHistoryFilter.reviewed => 'بها تقييم',
      WorkerHistoryFilter.pendingReview => 'بدون تقييم',
    };
  }

  bool matches(AcceptedWorkerRequest request) {
    return switch (this) {
      WorkerHistoryFilter.all => true,
      WorkerHistoryFilter.reviewed => request.review != null,
      WorkerHistoryFilter.pendingReview => request.review == null,
    };
  }
}

List<AcceptedWorkerRequest> filterWorkerHistory(
  List<AcceptedWorkerRequest> requests,
  WorkerHistoryFilter filter,
) {
  return requests
      .where((request) => filter.matches(request))
      .toList(growable: false);
}

String workerHistoryStatusLabel(String status) {
  return switch (status) {
    'completed' => 'مكتمل',
    'complaint' => 'شكوى',
    _ => status,
  };
}
