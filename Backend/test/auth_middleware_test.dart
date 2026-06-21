import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  const secret = 'test-jwt-secret';

  Handler buildAuthedHandler() {
    return Pipeline()
        .addMiddleware(
          authMiddleware(
            AppConfig(
              databaseUrl: 'postgresql://localhost/postgres',
              port: 8080,
              supabaseJwtSecret: secret,
            ),
          ),
        )
        .addHandler((Request request) {
          return Response.ok(readUserId(request) ?? '');
        });
  }

  test('auth middleware accepts valid bearer token', () async {
    final token = JWT(
      {'sub': 'user-123'},
      issuer: 'supabase',
    ).sign(SecretKey(secret));

    final response = await buildAuthedHandler()(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/requests/mine'),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'user-123');
  });

  test('auth middleware rejects missing authorization header', () async {
    final response = await buildAuthedHandler()(
      Request('GET', Uri.parse('http://localhost/v1/requests/mine')),
    );

    expect(response.statusCode, 401);
  });
}
