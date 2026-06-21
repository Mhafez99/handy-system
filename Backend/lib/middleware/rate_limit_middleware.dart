import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/rate_limit/rate_limit_result.dart';
import 'package:handy_backend/rate_limit/rate_limit_store.dart';
import 'package:handy_backend/rate_limit/request_rate_limit_rules.dart';
import 'package:shelf/shelf.dart';

Middleware rateLimitMiddleware({
  RateLimitStore? store,
  List<RateLimitRule> rules = requestRateLimitRules,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      if (store == null) {
        return innerHandler(request);
      }

      final userId = readUserId(request);
      if (userId == null) {
        return innerHandler(request);
      }

      RateLimitRule? matchedRule;
      for (final rule in rules) {
        if (rule.matches(request)) {
          matchedRule = rule;
          break;
        }
      }

      if (matchedRule == null) {
        return innerHandler(request);
      }

      RateLimitResult result;
      try {
        result = await store.consume(
          key: 'ratelimit:${matchedRule.name}:$userId',
          limit: matchedRule.limit,
          window: matchedRule.window,
        );
      } catch (_) {
        return innerHandler(request);
      }

      if (!result.allowed) {
        return jsonRateLimit(
          retryAfterSeconds: result.retryAfterSeconds,
          limit: result.limit,
        );
      }

      final response = await innerHandler(request);
      return response.change(
        headers: {
          'X-RateLimit-Limit': '${result.limit}',
          'X-RateLimit-Remaining': '${result.remaining}',
        },
      );
    };
  };
}
