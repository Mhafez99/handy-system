import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:handy_backend/auth/jwks_key_provider.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:shelf/shelf.dart';

const userIdContextKey = 'user_id';

const _hmacAlgorithms = {'HS256', 'HS384', 'HS512'};

Middleware authMiddleware(AppConfig config, {JwksKeyProvider? jwksProvider}) {
  final legacySecret = config.supabaseJwtSecret;
  final provider = jwksProvider ??
      (config.hasJwks ? JwksKeyProvider(config.supabaseJwksUrl!) : null);

  return (Handler innerHandler) {
    return (Request request) async {
      if (legacySecret == null && provider == null) {
        return jsonError(500, 'JWT verification is not configured');
      }

      final authorization = request.headers['Authorization'];
      if (authorization == null || !authorization.startsWith('Bearer ')) {
        return jsonError(401, 'Authorization required');
      }

      final token = authorization.substring('Bearer '.length).trim();
      if (token.isEmpty) {
        return jsonError(401, 'Authorization required');
      }

      final JWT header;
      try {
        header = JWT.decode(token);
      } on JWTException {
        return jsonError(401, 'Invalid token');
      } catch (_) {
        return jsonError(401, 'Invalid token');
      }

      final algorithm = header.header?['alg'] as String?;
      final kid = header.header?['kid'] as String?;

      JWTKey? key;
      if (algorithm != null && _hmacAlgorithms.contains(algorithm)) {
        if (legacySecret == null || legacySecret.isEmpty) {
          return jsonError(401, 'Invalid token');
        }
        key = SecretKey(legacySecret);
      } else {
        if (provider == null) {
          return jsonError(401, 'Invalid token');
        }
        try {
          key = await provider.keyForKid(kid);
        } catch (_) {
          return jsonError(401, 'Invalid token');
        }
        if (key == null) {
          return jsonError(401, 'Invalid token');
        }
      }

      try {
        final jwt = JWT.verify(token, key);
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
