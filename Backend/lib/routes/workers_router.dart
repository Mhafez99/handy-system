import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/workers_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildWorkersRouter(WorkersRepository repository) {
  final router = Router()
    ..post('/ratings/summary', (Request request) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final body = await readJsonBody(request);
      final rawWorkerIds = body['worker_ids'];

      if (rawWorkerIds is! List) {
        return jsonError(400, 'worker_ids is required');
      }

      final workerIds = rawWorkerIds
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final summaries = await repository.getWorkerRatingSummary(workerIds);
      return jsonOk(summaries);
    })
    ..get('/<workerId>', (Request request, String workerId) async {
      final userId = readUserId(request);
      if (userId == null) {
        return jsonError(401, 'Authorization required');
      }

      final details = await repository.getWorkerPublicDetails(workerId);
      return jsonOk(details);
    });

  return router.call;
}
