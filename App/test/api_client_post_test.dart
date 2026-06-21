import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/core/api/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('ApiClient posts JSON body', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:8080',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/requests/req-1/complete');
        expect(request.body, contains('"code":"123456"'));
        return http.Response('{"ok":true}', 200);
      }),
    );

    await client.postVoid(
      '/v1/requests/req-1/complete',
      body: {'code': '123456', 'final_price': 500},
    );
    client.close();
  });
}
