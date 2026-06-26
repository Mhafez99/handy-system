import 'package:handy_backend/cache/cache_store.dart';
import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/middleware/admin_middleware.dart';
import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/middleware/rate_limit_middleware.dart';
import 'package:handy_backend/push/fcm_client.dart';
import 'package:handy_backend/push/notification_service.dart';
import 'package:handy_backend/rate_limit/rate_limit_store.dart';
import 'package:handy_backend/repositories/admin_repository.dart';
import 'package:handy_backend/repositories/catalog_repository.dart';
import 'package:handy_backend/repositories/device_tokens_repository.dart';
import 'package:handy_backend/repositories/requests_repository.dart';
import 'package:handy_backend/repositories/workers_repository.dart';
import 'package:handy_backend/routes/admin_router.dart';
import 'package:handy_backend/routes/devices_router.dart';
import 'package:handy_backend/routes/handlers.dart';
import 'package:handy_backend/routes/requests_router.dart';
import 'package:handy_backend/routes/workers_router.dart';
import 'package:handy_backend/storage/supabase_storage_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class HandyApplication {
  HandyApplication({
    required this.config,
    required this.database,
    required this.handler,
    this.rateLimitStore,
    this.cacheStore,
  });

  final AppConfig config;
  final Database database;
  final Handler handler;
  final RateLimitStore? rateLimitStore;
  final CacheStore? cacheStore;

  Future<void> close() async {
    await rateLimitStore?.close();
    await cacheStore?.close();
    await database.close();
  }
}

Future<HandyApplication> buildHandyApplication(AppConfig config) async {
  final database = Database(
    writeUrl: config.databaseUrl,
    readUrl: config.readDatabaseUrl,
    poolSize: config.databasePoolSize,
    readPoolSize: config.readDatabasePoolSize,
    acquireTimeout: config.databaseAcquireTimeout,
    prewarmPools: config.prewarmDatabasePools,
  );
  await database.initialize();

  RateLimitStore? rateLimitStore;
  CacheStore? cacheStore;
  if (config.hasRateLimiting) {
    rateLimitStore = await connectRateLimitStore(config.redisUrl);
  }
  if (config.hasCaching) {
    cacheStore = await connectCacheStore(config.redisUrl);
  }

  final catalogRepository = CatalogRepository(
    database,
    cache: cacheStore,
    cacheTtl: Duration(seconds: config.catalogCacheTtlSeconds),
  );
  final deviceTokensRepository = DeviceTokensRepository(database);
  final fcmClient = config.hasPushNotifications
      ? FcmClient(serverKey: config.fcmServerKey!)
      : null;
  final notificationService = NotificationService(
    deviceTokens: deviceTokensRepository,
    database: database,
    fcm: fcmClient,
  );
  final storageClient = config.hasStorageSigning
      ? SupabaseStorageClient(
          supabaseUrl: config.supabaseUrl!,
          serviceRoleKey: config.supabaseServiceRoleKey!,
        )
      : null;
  final requestsRepository = RequestsRepository(
    database,
    storage: storageClient,
    notifications: notificationService,
    cache: cacheStore,
    workerAvailableCacheTtl: Duration(
      seconds: config.workerAvailableCacheTtlSeconds,
    ),
  );
  final workersRepository = WorkersRepository(database);
  final adminRepository = AdminRepository(
    database,
    cache: cacheStore,
    statsCacheTtl: Duration(seconds: config.adminStatsCacheTtlSeconds),
  );

  final authenticatedRequestsHandler = Pipeline()
      .addMiddleware(authMiddleware(config))
      .addMiddleware(rateLimitMiddleware(store: rateLimitStore))
      .addHandler(buildRequestsRouter(requestsRepository));

  final authenticatedWorkersHandler = Pipeline()
      .addMiddleware(authMiddleware(config))
      .addHandler(buildWorkersRouter(workersRepository));

  final authenticatedDevicesHandler = Pipeline()
      .addMiddleware(authMiddleware(config))
      .addHandler(buildDevicesRouter(deviceTokensRepository));

  final authenticatedAdminHandler = Pipeline()
      .addMiddleware(authMiddleware(config))
      .addMiddleware(adminMiddleware(adminRepository))
      .addHandler(buildAdminRouter(adminRepository));

  final router = Router()
    ..get('/health', buildHealthHandler())
    ..get('/ready', buildReadyHandler(database))
    ..mount('/v1/catalog', buildCatalogRouter(catalogRepository))
    ..mount('/v1/requests', authenticatedRequestsHandler)
    ..mount('/v1/workers', authenticatedWorkersHandler)
    ..mount('/v1/devices', authenticatedDevicesHandler)
    ..mount('/v1/admin', authenticatedAdminHandler);

  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(jsonErrorMiddleware())
      .addHandler(router.call);

  return HandyApplication(
    config: config,
    database: database,
    handler: handler,
    rateLimitStore: rateLimitStore,
    cacheStore: cacheStore,
  );
}
