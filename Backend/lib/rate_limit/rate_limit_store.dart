import 'package:handy_backend/rate_limit/rate_limit_result.dart';
import 'package:redis/redis.dart';

abstract class RateLimitStore {
  Future<RateLimitResult> consume({
    required String key,
    required int limit,
    required Duration window,
  });

  Future<void> close() async {}
}

class InMemoryRateLimitStore implements RateLimitStore {
  final Map<String, _RateLimitWindow> _windows = {};

  @override
  Future<RateLimitResult> consume({
    required String key,
    required int limit,
    required Duration window,
  }) async {
    final now = DateTime.now().toUtc();
    final current = _windows[key];

    if (current == null || !current.expiresAt.isAfter(now)) {
      _windows[key] = _RateLimitWindow(
        count: 1,
        expiresAt: now.add(window),
      );
      return RateLimitResult.allowed(limit: limit, count: 1);
    }

    current.count += 1;
    if (current.count > limit) {
      final retryAfter = current.expiresAt.difference(now).inSeconds;
      return RateLimitResult.denied(
        limit: limit,
        retryAfterSeconds: retryAfter > 0 ? retryAfter : window.inSeconds,
      );
    }

    return RateLimitResult.allowed(limit: limit, count: current.count);
  }

  @override
  Future<void> close() async {}
}

class _RateLimitWindow {
  _RateLimitWindow({required this.count, required this.expiresAt});

  int count;
  final DateTime expiresAt;
}

class RedisRateLimitStore implements RateLimitStore {
  RedisRateLimitStore(this._command);

  final Command _command;

  static Future<RedisRateLimitStore> connect(String redisUrl) async {
    final config = _RedisConfig.fromUrl(redisUrl);
    final connection = RedisConnection();
    final command = config.useTls
        ? await connection.connectSecure(config.host, config.port)
        : await connection.connect(config.host, config.port);

    if (config.password != null && config.password!.isNotEmpty) {
      if (config.username != null && config.username!.isNotEmpty) {
        await command.send_object([
          'AUTH',
          config.username,
          config.password,
        ]);
      } else {
        await command.send_object(['AUTH', config.password]);
      }
    }

    return RedisRateLimitStore(command);
  }

  @override
  Future<RateLimitResult> consume({
    required String key,
    required int limit,
    required Duration window,
  }) async {
    final count = _asInt(await _command.send_object(['INCR', key]));
    if (count == 1) {
      await _command.send_object(['EXPIRE', key, window.inSeconds]);
    }

    if (count > limit) {
      final ttl = _asInt(await _command.send_object(['TTL', key]));
      return RateLimitResult.denied(
        limit: limit,
        retryAfterSeconds: ttl > 0 ? ttl : window.inSeconds,
      );
    }

    return RateLimitResult.allowed(limit: limit, count: count);
  }

  @override
  Future<void> close() async {
    _command.get_connection().close();
  }

  int _asInt(Object? value) {
    return switch (value) {
      final int number => number,
      final String text => int.parse(text),
      _ => throw const FormatException('Expected integer response from Redis'),
    };
  }
}

class _RedisConfig {
  const _RedisConfig({
    required this.host,
    required this.port,
    required this.useTls,
    this.username,
    this.password,
  });

  factory _RedisConfig.fromUrl(String redisUrl) {
    final uri = Uri.parse(redisUrl);
    if (uri.host.isEmpty) {
      throw FormatException('Invalid REDIS_URL: $redisUrl');
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'redis' && scheme != 'rediss') {
      throw FormatException('REDIS_URL must use redis:// or rediss://');
    }

    String? username;
    String? password;
    if (uri.userInfo.isNotEmpty) {
      final parts = uri.userInfo.split(':');
      if (parts.length == 2) {
        username = Uri.decodeComponent(parts[0]);
        password = Uri.decodeComponent(parts[1]);
      } else {
        password = Uri.decodeComponent(uri.userInfo);
      }
    }

    return _RedisConfig(
      host: uri.host,
      port: uri.port == 0 ? 6379 : uri.port,
      useTls: scheme == 'rediss',
      username: username,
      password: password,
    );
  }

  final String host;
  final int port;
  final bool useTls;
  final String? username;
  final String? password;
}

Future<RateLimitStore?> connectRateLimitStore(String? redisUrl) async {
  final url = redisUrl?.trim();
  if (url == null || url.isEmpty) {
    return null;
  }

  return RedisRateLimitStore.connect(url);
}
