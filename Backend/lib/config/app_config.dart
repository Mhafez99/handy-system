import 'dart:io';

class AppConfig {
  AppConfig({
    required this.databaseUrl,
    required this.port,
    this.supabaseUrl,
    this.supabaseJwtSecret,
    this.supabaseServiceRoleKey,
    this.redisUrl,
    this.fcmServerKey,
  });

  factory AppConfig.fromEnvironment([Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    final databaseUrl = env['DATABASE_URL']?.trim() ?? '';
    final port = int.tryParse(env['PORT'] ?? '') ?? 8080;

    if (databaseUrl.isEmpty) {
      throw StateError('DATABASE_URL is required');
    }

    return AppConfig(
      databaseUrl: databaseUrl,
      port: port,
      supabaseUrl: env['SUPABASE_URL']?.trim(),
      supabaseJwtSecret: env['SUPABASE_JWT_SECRET']?.trim(),
      supabaseServiceRoleKey: env['SUPABASE_SERVICE_ROLE_KEY']?.trim(),
      redisUrl: env['REDIS_URL']?.trim(),
      fcmServerKey: env['FCM_SERVER_KEY']?.trim(),
    );
  }

  final String databaseUrl;
  final int port;
  final String? supabaseUrl;
  final String? supabaseJwtSecret;
  final String? supabaseServiceRoleKey;
  final String? redisUrl;
  final String? fcmServerKey;

  bool get hasStorageSigning =>
      (supabaseUrl?.isNotEmpty ?? false) &&
      (supabaseServiceRoleKey?.isNotEmpty ?? false);

  bool get hasRateLimiting => redisUrl?.isNotEmpty ?? false;

  bool get hasPushNotifications => fcmServerKey?.isNotEmpty ?? false;
}
