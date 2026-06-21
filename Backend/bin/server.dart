import 'dart:io';

import 'package:handy_backend/config/app_config.dart';
import 'package:handy_backend/db/database.dart';
import 'package:handy_backend/middleware/auth_middleware.dart';
import 'package:handy_backend/middleware/http_middleware.dart';
import 'package:handy_backend/middleware/rate_limit_middleware.dart';
import 'package:handy_backend/rate_limit/rate_limit_store.dart';
import 'package:handy_backend/push/fcm_client.dart';
import 'package:handy_backend/push/notification_service.dart';
import 'package:handy_backend/repositories/catalog_repository.dart';
import 'package:handy_backend/repositories/device_tokens_repository.dart';
import 'package:handy_backend/repositories/requests_repository.dart';
import 'package:handy_backend/repositories/workers_repository.dart';
import 'package:handy_backend/routes/devices_router.dart';
import 'package:handy_backend/routes/handlers.dart';
import 'package:handy_backend/routes/requests_router.dart';
import 'package:handy_backend/routes/workers_router.dart';
import 'package:handy_backend/storage/supabase_storage_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main(List<String> args) async {
  final environment = _loadEnvironment();
  final config = AppConfig.fromEnvironment(environment);
  final database = Database(config.databaseUrl);
  RateLimitStore? rateLimitStore;
  if (config.hasRateLimiting) {
    try {
      rateLimitStore = await connectRateLimitStore(config.redisUrl);
      stdout.writeln('Rate limiting enabled (Redis)');
    } catch (error) {
      stderr.writeln(
        'Rate limiting disabled: unable to connect to Redis ($error)',
      );
    }
  }
  final catalogRepository = CatalogRepository(database);
  final deviceTokensRepository = DeviceTokensRepository(database);
  FcmClient? fcmClient;
  if (config.hasPushNotifications) {
    fcmClient = FcmClient(serverKey: config.fcmServerKey!);
    stdout.writeln('Push notifications enabled (FCM)');
  }
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
  );
  final workersRepository = WorkersRepository(database);

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

  final router = Router()
    ..get('/health', buildHealthHandler())
    ..mount('/v1/catalog', buildCatalogRouter(catalogRepository))
    ..mount('/v1/requests', authenticatedRequestsHandler)
    ..mount('/v1/workers', authenticatedWorkersHandler)
    ..mount('/v1/devices', authenticatedDevicesHandler);

  final handler = Pipeline()
      .addMiddleware(corsMiddleware())
      .addMiddleware(jsonErrorMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );

  stdout.writeln(
    'Handy API listening on http://${server.address.host}:${server.port}',
  );
}

Map<String, String> _loadEnvironment() {
  final environment = Map<String, String>.from(Platform.environment);
  final file = File('.env');

  if (!file.existsSync()) {
    return environment;
  }

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    final separatorIndex = trimmed.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    final key = trimmed.substring(0, separatorIndex).trim();
    final value = trimmed.substring(separatorIndex + 1).trim();
    if (key.isNotEmpty) {
      environment[key] = value;
    }
  }

  return environment;
}
