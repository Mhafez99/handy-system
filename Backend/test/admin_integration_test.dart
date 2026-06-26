import 'package:shelf/shelf.dart';
import 'package:test/support/fake_admin_operations.dart';
import 'package:test/support/test_http.dart';
import 'package:test/test.dart';

void main() {
  group('admin integration', () {
    late FakeAdminOperations admin;
    late Handler handler;

    setUp(() {
      admin = FakeAdminOperations();
      handler = buildTestAdminHandler(admin);
    });

    test('rejects unauthenticated requests', () async {
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/overview/stats')),
      );

      expect(response.statusCode, 401);
    });

    test('rejects non-admin users', () async {
      final response = await handler(
        adminRequest('GET', '/overview/stats', userId: testRegularUserId),
      );

      expect(response.statusCode, 403);
    });

    test('GET /overview/stats returns dashboard stats', () async {
      final response = await handler(
        adminRequest('GET', '/overview/stats'),
      );

      expect(response.statusCode, 200);
      final body = await readJsonMap(response);
      expect(body['total_requests'], 10);
      expect(admin.calls, contains('getOverviewStats'));
    });

    test('GET /overview/trend returns daily trend', () async {
      final response = await handler(
        adminRequest('GET', '/overview/trend'),
      );

      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body, hasLength(1));
      expect(admin.calls, contains('getOverviewDailyTrend'));
    });

    test('GET /requests/recent returns recent requests', () async {
      final response = await handler(
        adminRequest(
          'GET',
          '/requests/recent?limit=5&status=new',
        ),
      );

      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['status'], 'new');
      expect(admin.calls, contains('listRecentRequests'));
    });

    test('GET /workers/pending returns pending workers', () async {
      final response = await handler(
        adminRequest('GET', '/workers/pending'),
      );

      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['user_id'], 'worker-1');
    });

    test('POST /workers/:id/approve approves worker', () async {
      final response = await handler(
        adminRequest('POST', '/workers/worker-1/approve'),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('approveWorker:worker-1'));
    });

    test('POST /workers/:id/reject rejects worker', () async {
      final response = await handler(
        adminRequest('POST', '/workers/worker-1/reject'),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('rejectWorker:worker-1'));
    });

    test('GET /areas returns areas', () async {
      final response = await handler(adminRequest('GET', '/areas'));
      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['name'], 'المعادي');
    });

    test('POST /areas creates area', () async {
      final response = await handler(
        adminRequest(
          'POST',
          '/areas',
          body: {
            'governorate': 'القاهرة',
            'name': 'مدينة نصر',
            'sort_order': 2,
          },
        ),
      );

      expect(response.statusCode, 201);
      final body = await readJsonMap(response);
      expect(body['id'], 2);
      expect(admin.calls, contains('createArea'));
    });

    test('PATCH /areas/:id updates area', () async {
      final response = await handler(
        adminRequest(
          'PATCH',
          '/areas/1',
          body: {
            'governorate': 'القاهرة',
            'name': 'المعادي',
            'sort_order': 1,
            'is_active': true,
          },
        ),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('updateArea:1'));
    });

    test('GET /complaints returns complaints', () async {
      final response = await handler(adminRequest('GET', '/complaints'));
      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['status'], 'open');
    });

    test('PATCH /complaints/:id updates complaint status', () async {
      final response = await handler(
        adminRequest(
          'PATCH',
          '/complaints/complaint-1',
          body: {'status': 'resolved'},
        ),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('updateComplaintStatus:complaint-1'));
    });

    test('GET /users returns users', () async {
      final response = await handler(
        adminRequest('GET', '/users?role=customer&status=active'),
      );

      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['role'], 'customer');
    });

    test('PATCH /users/:id/status updates user status', () async {
      final response = await handler(
        adminRequest(
          'PATCH',
          '/users/user-1/status',
          body: {'status': 'suspended'},
        ),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('updateUserStatus:user-1'));
    });

    test('GET /categories returns categories', () async {
      final response = await handler(adminRequest('GET', '/categories'));
      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['name'], 'سباكة');
    });

    test('POST /categories creates category', () async {
      final response = await handler(
        adminRequest(
          'POST',
          '/categories',
          body: {'name': 'كهرباء', 'sort_order': 2},
        ),
      );

      expect(response.statusCode, 201);
      final body = await readJsonMap(response);
      expect(body['id'], 3);
    });

    test('PATCH /categories/:id updates category', () async {
      final response = await handler(
        adminRequest(
          'PATCH',
          '/categories/1',
          body: {
            'name': 'سباكة',
            'sort_order': 1,
            'is_active': false,
          },
        ),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('updateCategory:1'));
    });

    test('GET /services returns services', () async {
      final response = await handler(
        adminRequest('GET', '/services?category_id=1'),
      );

      expect(response.statusCode, 200);
      final body = await readJsonList(response);
      expect(body.first['category_id'], 1);
    });

    test('POST /services creates service', () async {
      final response = await handler(
        adminRequest(
          'POST',
          '/services',
          body: {
            'category_id': 1,
            'name': 'تركيب خلاط',
            'min_price': 150,
            'max_price': 250,
          },
        ),
      );

      expect(response.statusCode, 201);
      final body = await readJsonMap(response);
      expect(body['id'], 4);
    });

    test('PATCH /services/:id updates service', () async {
      final response = await handler(
        adminRequest(
          'PATCH',
          '/services/1',
          body: {
            'category_id': 1,
            'name': 'تسليك مجاري',
            'min_price': 100,
            'max_price': 300,
            'is_active': true,
          },
        ),
      );

      expect(response.statusCode, 200);
      expect(admin.calls, contains('updateService:1'));
    });

    test('PATCH /areas/:id rejects invalid id', () async {
      final response = await handler(
        adminRequest(
          'PATCH',
          '/areas/not-a-number',
          body: {
            'governorate': 'القاهرة',
            'name': 'المعادي',
            'sort_order': 1,
            'is_active': true,
          },
        ),
      );

      expect(response.statusCode, 400);
    });
  });
}
