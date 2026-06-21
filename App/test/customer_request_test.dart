import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';

void main() {
  test('CustomerRequest reads offer_count from API payload', () {
    final request = CustomerRequest.fromJson({
      'id': 'req-1',
      'area': 'مدينة نصر',
      'status': 'offered',
      'created_at': '2026-06-20T10:00:00.000Z',
      'offer_count': 3,
      'services': {
        'name': 'تركيب خلاط',
        'categories': {'name': 'سباك'},
      },
      'offers': [],
    });

    expect(request.offerCount, 3);
  });
}
