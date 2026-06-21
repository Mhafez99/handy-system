import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/customer/domain/customer_request_filter.dart';
import 'package:handy_app/features/customer/presentation/customer_request_widgets.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';

CustomerRequest _request(String status) {
  return CustomerRequest(
    id: 'request-$status',
    serviceName: 'تركيب خلاط',
    categoryName: 'سباك',
    area: 'مدينة نصر',
    status: status,
    offerCount: 1,
    createdAt: DateTime(2026, 6, 20),
  );
}

void main() {
  test('active filter includes in-progress requests only', () {
    final requests = [
      _request('new'),
      _request('completed'),
      _request('in_progress'),
      _request('cancelled'),
    ];

    final filtered = filterCustomerRequests(
      requests,
      CustomerRequestFilter.active,
    );

    expect(filtered.map((request) => request.status), ['new', 'in_progress']);
  });

  test('completed filter excludes active requests', () {
    final requests = [
      _request('accepted'),
      _request('completed'),
      _request('complaint'),
    ];

    final filtered = filterCustomerRequests(
      requests,
      CustomerRequestFilter.completed,
    );

    expect(filtered, hasLength(1));
    expect(filtered.first.status, 'completed');
  });
}
