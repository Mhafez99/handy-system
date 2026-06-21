import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:shelf/shelf.dart';

const userIdContextKey = 'user_id';

Middleware authMiddleware(AppConfig config) {
  return (Handler innerHandler) {
    return (Request request) async {
      final secret = config.supabaseJwtSecret;
      if (secret == null || secret.isEmpty) {
        return jsonError(500, 'JWT secret is not configured');
      }

      final authorization = request.headers['Authorization'];
      if (authorization == null || !authorization.startsWith('Bearer ')) {
        return jsonError(401, 'Authorization required');
      }

      final token = authorization.substring('Bearer '.length).trim();
      if (token.isEmpty) {
        return jsonError(401, 'Authorization required');
      }

      try {
        final jwt = JWT.verify(token, SecretKey(secret));
        final payload = jwt.payload;
        final userId = payload is Map ? payload['sub'] : null;

        if (userId is! String || userId.isEmpty) {
          return jsonError(401, 'Invalid token');
        }

        return innerHandler(
          request.change(context: {userIdContextKey: userId}),
        );
      } on JWTException {
        return jsonError(401, 'Invalid token');
      }
    };
  };
}

String? readUserId(Request request) {
  final value = request.context[userIdContextKey];
  return value is String ? value : null;
}
