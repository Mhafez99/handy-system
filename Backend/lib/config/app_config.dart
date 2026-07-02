import 'dart:io';

class AppConfig {
  AppConfig({
    required this.databaseUrl,
    required this.port,
    this.readDatabaseUrl,
    this.databasePoolSize = 25,
    this.readDatabasePoolSize = 25,
    this.databaseAcquireTimeoutSeconds = 30,
    this.prewarmDatabasePools = true,
    this.supabaseUrl,
    this.supabaseJwtSecret,
    this.supabaseJwksUrl,
    this.supabaseServiceRoleKey,
    this.redisUrl,
    this.fcmServerKey,
    this.adminStatsCacheTtlSeconds = 60,
    this.catalogCacheTtlSeconds = 300,
    this.workerAvailableCacheTtlSeconds = 20,
  });

  factory AppConfig.fromEnvironment([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    final databaseUrl = env['DATABASE_URL']?.trim() ?? '';
    final readDatabaseUrl = env['READ_DATABASE_URL']?.trim();
    final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
    final databasePoolSize = int.tryParse(env['DB_POOL_SIZE'] ?? '') ?? 25;
    final readDatabasePoolSize =
        int.tryParse(env['DB_READ_POOL_SIZE'] ?? '') ?? databasePoolSize;
    final databaseAcquireTimeoutSeconds =
        int.tryParse(env['DB_ACQUIRE_TIMEOUT_SECONDS'] ?? '') ?? 30;
    final adminStatsCacheTtlSeconds =
        int.tryParse(env['ADMIN_STATS_CACHE_TTL_SECONDS'] ?? '') ?? 60;
    final catalogCacheTtlSeconds =
        int.tryParse(env['CATALOG_CACHE_TTL_SECONDS'] ?? '') ?? 300;
    final workerAvailableCacheTtlSeconds =
        int.tryParse(env['WORKER_AVAILABLE_CACHE_TTL_SECONDS'] ?? '') ?? 20;
    final prewarmDatabasePools = _parseBool(
      env['DB_PREWARM_POOLS'],
      defaultValue: true,
    );

    if (databaseUrl.isEmpty) {
      throw StateError('DATABASE_URL is required');
    }

    return AppConfig(
      databaseUrl: databaseUrl,
      readDatabaseUrl:
          readDatabaseUrl == null || readDatabaseUrl.isEmpty
              ? null
              : readDatabaseUrl,
      port: port,
      databasePoolSize: databasePoolSize.clamp(1, 100),
      readDatabasePoolSize: readDatabasePoolSize.clamp(1, 100),
      databaseAcquireTimeoutSeconds: databaseAcquireTimeoutSeconds.clamp(5, 120),
      prewarmDatabasePools: prewarmDatabasePools,
      supabaseUrl: env['SUPABASE_URL']?.trim(),
      supabaseJwtSecret: env['SUPABASE_JWT_SECRET']?.trim(),
      supabaseJwksUrl: _resolveJwksUrl(env),
      supabaseServiceRoleKey: env['SUPABASE_SERVICE_ROLE_KEY']?.trim(),
      redisUrl: env['REDIS_URL']?.trim(),
      fcmServerKey: env['FCM_SERVER_KEY']?.trim(),
      adminStatsCacheTtlSeconds: adminStatsCacheTtlSeconds.clamp(5, 3600),
      catalogCacheTtlSeconds: catalogCacheTtlSeconds.clamp(30, 3600),
      workerAvailableCacheTtlSeconds: workerAvailableCacheTtlSeconds.clamp(
        5,
        120,
      ),
    );
  }

  final String databaseUrl;
  final String? readDatabaseUrl;
  final int port;
  final int databasePoolSize;
  final int readDatabasePoolSize;
  final int databaseAcquireTimeoutSeconds;
  final bool prewarmDatabasePools;
  final String? supabaseUrl;
  final String? supabaseJwtSecret;
  final String? supabaseJwksUrl;
  final String? supabaseServiceRoleKey;
  final String? redisUrl;
  final String? fcmServerKey;
  final int adminStatsCacheTtlSeconds;
  final int catalogCacheTtlSeconds;
  final int workerAvailableCacheTtlSeconds;

  bool get hasReadReplica =>
      readDatabaseUrl != null && readDatabaseUrl != databaseUrl;

  bool get hasJwtSecret => supabaseJwtSecret?.isNotEmpty ?? false;

  bool get hasJwks => supabaseJwksUrl?.isNotEmpty ?? false;

  bool get hasAuth => hasJwtSecret || hasJwks;

  bool get hasStorageSigning =>
      (supabaseUrl?.isNotEmpty ?? false) &&
      (supabaseServiceRoleKey?.isNotEmpty ?? false);

  bool get hasRateLimiting => redisUrl?.isNotEmpty ?? false;

  bool get hasCaching => redisUrl?.isNotEmpty ?? false;

  bool get hasPushNotifications => fcmServerKey?.isNotEmpty ?? false;

  Duration get databaseAcquireTimeout =>
      Duration(seconds: databaseAcquireTimeoutSeconds);

  static String? _resolveJwksUrl(Map<String, String> env) {
    final explicit = env['SUPABASE_JWKS_URL']?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final supabaseUrl = env['SUPABASE_URL']?.trim();
    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      return null;
    }

    final normalized = supabaseUrl.endsWith('/')
        ? supabaseUrl.substring(0, supabaseUrl.length - 1)
        : supabaseUrl;
    return '$normalized/auth/v1/.well-known/jwks.json';
  }

  static bool _parseBool(String? rawValue, {required bool defaultValue}) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return defaultValue;
    }

    switch (rawValue.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
      default:
        return defaultValue;
    }
  }
}
