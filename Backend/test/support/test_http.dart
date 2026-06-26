import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/middleware/admin_middleware.dart';
import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/admin_operations.dart';
import 'package:handy_backend/routes/admin_router.dart';
import 'package:shelf/shelf.dart';

const testJwtSecret = 'test-jwt-secret';
const testAdminUserId = '11111111-1111-1111-1111-111111111111';
const testRegularUserId = '22222222-2222-2222-2222-222222222222';

Handler buildTestAdminHandler(AdminOperations admin) {
  final config = AppConfig(
    databaseUrl: 'postgresql://localhost/postgres',
    port: 8080,
    supabaseJwtSecret: testJwtSecret,
  );

  return Pipeline()
      .addMiddleware(jsonErrorMiddleware())
      .addMiddleware(authMiddleware(config))
      .addMiddleware(adminMiddleware(admin))
      .addHandler(buildAdminRouter(admin));
}

String signTestToken(String userId) {
  return JWT(
    {'sub': userId},
    issuer: 'supabase',
  ).sign(SecretKey(testJwtSecret));
}

Map<String, String> authHeaders(String userId) {
  return {'Authorization': 'Bearer ${signTestToken(userId)}'};
}

Future<Map<String, dynamic>> readJsonMap(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<List<dynamic>> readJsonList(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as List<dynamic>;
}

Request adminRequest(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String userId = testAdminUserId,
}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: {
      ...authHeaders(userId),
      if (body != null) 'Content-Type': 'application/json',
    },
    body: body == null ? null : jsonEncode(body),
  );
}
