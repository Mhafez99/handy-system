import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/device_tokens_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildDevicesRouter(DeviceTokensRepository repository) {
  final router = Router()
    ..put('/token', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final token = body['token'];
      final platform = body['platform'];

      if (token is! String || platform is! String) {
        return jsonError(400, 'Invalid device token payload');
      }

      await repository.upsertToken(
        userId: userId,
        token: token,
        platform: platform,
      );

      return jsonOk({'ok': true});
    })
    ..delete('/token', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final token = body['token'];

      if (token is! String) {
        return jsonError(400, 'Invalid device token payload');
      }

      await repository.deleteToken(
        userId: userId,
        token: token,
      );

      return jsonOk({'ok': true});
    });

  return router.call;
}
