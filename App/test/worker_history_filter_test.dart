import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';
import 'package:handy_app/features/worker/domain/worker_history_filter.dart';

AcceptedWorkerRequest _completedRequest({ServiceReview? review}) {
  return AcceptedWorkerRequest(
    id: 'request-1',
    serviceName: 'تركيب خلاط',
    categoryName: 'سباك',
    description: 'محتاج تركيب خلاط',
    governorate: 'القاهرة',
    area: 'مدينة نصر',
    address: 'شارع 1',
    preferredTime: 'بكرة',
    status: 'completed',
    customerName: 'محمد',
    customerPhone: '01000000000',
    customerAddress: 'عنوان',
    acceptedPrice: 300,
    arrivalTime: 'ساعة',
    createdAt: DateTime(2026, 6, 20),
    review: review,
    finalPrice: 300,
    paymentMethod: 'cash',
  );
}

void main() {
  test('reviewed filter keeps only rated completed jobs', () {
    final requests = [
      _completedRequest(
        review: ServiceReview(
          id: 'review-1',
          rating: 5,
          comment: 'ممتاز',
          createdAt: DateTime(2026, 6, 20),
        ),
      ),
      _completedRequest(),
    ];

    final filtered = filterWorkerHistory(
      requests,
      WorkerHistoryFilter.reviewed,
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.review?.rating, 5);
  });

  test('pending review filter excludes rated jobs', () {
    final requests = [
      _completedRequest(
        review: ServiceReview(
          id: 'review-1',
          rating: 4,
          comment: '',
          createdAt: DateTime(2026, 6, 20),
        ),
      ),
      _completedRequest(),
    ];

    final filtered = filterWorkerHistory(
      requests,
      WorkerHistoryFilter.pendingReview,
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.review, isNull);
  });
}
