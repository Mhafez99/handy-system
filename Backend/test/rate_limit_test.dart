import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/rate_limit_middleware.dart';
import 'package:handy_backend/rate_limit/rate_limit_store.dart';
import 'package:handy_backend/rate_limit/request_rate_limit_rules.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  const secret = 'test-jwt-secret';

  Handler buildHandler({
    required RateLimitStore store,
    List<RateLimitRule> rules = requestRateLimitRules,
  }) {
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
        .addMiddleware(rateLimitMiddleware(store: store, rules: rules))
        .addHandler((_) => Response.ok('ok'));
  }

  Request authedRequest(String method, String path) {
    final token = JWT(
      {'sub': 'user-123'},
      issuer: 'supabase',
    ).sign(SecretKey(secret));

    return Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  test('allows requests under the limit', () async {
    final store = InMemoryRateLimitStore();
    final handler = buildHandler(
      store: store,
      rules: [
        RateLimitRule(
          name: 'test',
          matches: (request) => request.method == 'POST',
          limit: 2,
          window: const Duration(minutes: 1),
        ),
      ],
    );

    expect((await handler(authedRequest('POST', '/'))).statusCode, 200);
    expect((await handler(authedRequest('POST', '/'))).statusCode, 200);
  });

  test('blocks requests over the limit with 429', () async {
    final store = InMemoryRateLimitStore();
    final handler = buildHandler(
      store: store,
      rules: [
        RateLimitRule(
          name: 'test',
          matches: (request) => request.method == 'POST',
          limit: 2,
          window: const Duration(minutes: 1),
        ),
      ],
    );

    await handler(authedRequest('POST', '/'));
    await handler(authedRequest('POST', '/'));
    final response = await handler(authedRequest('POST', '/'));

    expect(response.statusCode, 429);
    expect(response.headers['retry-after'], isNotNull);
    expect(response.headers['x-ratelimit-remaining'], '0');
  });

  test('create request rule matches POST /', () {
    final request = Request('POST', Uri.parse('http://localhost/'));
    expect(_isCreateRequest(request), isTrue);
  });

  test('available requests rule matches GET /available', () {
    final request = Request(
      'GET',
      Uri.http('localhost', 'available'),
    );
    expect(_isAvailableRequests(request), isTrue);
  });

  test('create offer rule matches POST /request-id/offers', () {
    final request = Request(
      'POST',
      Uri.http('localhost', 'abc/offers'),
    );
    expect(_isCreateOffer(request), isTrue);
  });
}

bool _isCreateRequest(Request request) {
  return requestRateLimitRules
      .firstWhere((rule) => rule.name == 'create_request')
      .matches(request);
}

bool _isAvailableRequests(Request request) {
  return requestRateLimitRules
      .firstWhere((rule) => rule.name == 'available_requests')
      .matches(request);
}

bool _isCreateOffer(Request request) {
  return requestRateLimitRules
      .firstWhere((rule) => rule.name == 'create_offer')
      .matches(request);
}
