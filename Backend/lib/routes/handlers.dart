import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/repositories/catalog_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildCatalogRouter(CatalogRepository repository) {
  final router = Router()
    ..get('/categories', (Request request) async {
      final categories = await repository.listCategories();
      return jsonOk(categories);
    })
    ..get('/services', (Request request) async {
      final categoryId = int.tryParse(
        request.url.queryParameters['category_id'] ?? '',
      );
      final services = await repository.listServices(categoryId: categoryId);
      return jsonOk(services);
    })
    ..get('/areas', (Request request) async {
      final areas = await repository.listAreas();
      return jsonOk(areas);
    });

  return router.call;
}

Handler buildHealthHandler() {
  return (Request request) {
    return jsonOk({
      'status': 'ok',
      'service': 'handy-api',
      'version': '0.1.0',
    });
  };
}

Handler buildReadyHandler(Database database) {
  return (Request request) async {
    try {
      final writeReady = await database.pingWritePool();
      final readReady = await database.pingReadPool();
      if (!writeReady || !readReady) {
        return jsonError(503, 'Database is not ready');
      }

      return jsonOk({
        'status': 'ready',
        'database': {
          'write': writeReady,
          'read': readReady,
        },
      });
    } catch (_) {
      return jsonError(503, 'Database is not ready');
    }
  };
}
