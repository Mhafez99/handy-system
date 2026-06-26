import 'package:handy_backend/repositories/admin_operations.dart';
import 'package:shelf/shelf.dart';
import 'package:test/support/fake_admin_operations.dart';
import 'package:test/support/test_http.dart';
import 'package:test/test.dart';

void main() {
  test('admin middleware allows admin users', () async {
    final admin = FakeAdminOperations();
    final handler = buildTestAdminHandler(admin);

    final response = await handler(
      adminRequest('GET', '/workers/pending'),
    );

    expect(response.statusCode, 200);
    expect(admin.calls, contains('isAdmin:$testAdminUserId'));
  });

  test('admin middleware blocks regular users before router runs', () async {
    final admin = FakeAdminOperations();
    final handler = buildTestAdminHandler(admin);

    final response = await handler(
      adminRequest('GET', '/workers/pending', userId: testRegularUserId),
    );

    expect(response.statusCode, 403);
    expect(admin.calls.where((call) => call == 'listPendingWorkers'), isEmpty);
  });
}
