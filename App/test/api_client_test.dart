import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/core/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('ApiClient parses list responses', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8080',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/v1/catalog/categories');
        return http.Response(
          '[{"id":1,"name":"سباك"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final rows = await client.getList('/v1/catalog/categories');

    expect(rows, hasLength(1));
    expect(rows.first['name'], 'سباك');
    client.close();
  });

  test('ApiClient surfaces server errors', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8080',
      httpClient: MockClient((request) async {
        return http.Response(
          '{"error":"Database unavailable"}',
          500,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(
      client.getList('/v1/catalog/areas'),
      throwsA(predicate((error) => error.toString().contains('Database'))),
    );
    client.close();
  });
}
