import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/admin_operations.dart';
import 'package:shelf/shelf.dart';

Middleware adminMiddleware(AdminOperations repository) {
  return (Handler innerHandler) {
    return (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final isAdmin = await repository.isAdmin(userId);
      if (!isAdmin) {
        return jsonError(403, 'Admin access required');
      }

      return innerHandler(request);
    };
  };
}
