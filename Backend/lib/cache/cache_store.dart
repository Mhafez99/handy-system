import 'dart:convert';

import 'package:redis/redis.dart';

abstract class CacheStore {
  Future<String?> get(String key);

  Future<void> set({
    required String key,
    required String value,
    required Duration ttl,
  });

  Future<void> delete(String key);

  Future<void> deleteByPrefix(String prefix);

  Future<void> close() async {}
}

class InMemoryCacheStore implements CacheStore {
  final Map<String, _CacheEntry> _entries = {};

  @override
  Future<String?> get(String key) async {
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }

    if (!entry.expiresAt.isAfter(DateTime.now().toUtc())) {
      _entries.remove(key);
      return null;
    }

    return entry.value;
  }

  @override
  Future<void> set({
    required String key,
    required String value,
    required Duration ttl,
  }) async {
    _entries[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().toUtc().add(ttl),
    );
  }

  @override
  Future<void> delete(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> deleteByPrefix(String prefix) async {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<void> close() async {
    _entries.clear();
  }
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});

  final String value;
  final DateTime expiresAt;
}

class RedisCacheStore implements CacheStore {
  RedisCacheStore(this._command);

  final Command _command;

  static Future<RedisCacheStore> connect(String redisUrl) async {
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

    return RedisCacheStore(command);
  }

  @override
  Future<String?> get(String key) async {
    final value = await _command.send_object(['GET', key]);
    return value?.toString();
  }

  @override
  Future<void> set({
    required String key,
    required String value,
    required Duration ttl,
  }) async {
    await _command.send_object(['SET', key, value, 'EX', ttl.inSeconds]);
  }

  @override
  Future<void> delete(String key) async {
    await _command.send_object(['DEL', key]);
  }

  @override
  Future<void> deleteByPrefix(String prefix) async {
    var cursor = '0';

    do {
      final response = await _command.send_object([
        'SCAN',
        cursor,
        'MATCH',
        '$prefix*',
        'COUNT',
        100,
      ]);

      if (response is! List || response.length < 2) {
        break;
      }

      cursor = response[0].toString();
      final keys = response[1];
      if (keys is List && keys.isNotEmpty) {
        await _command.send_object(['DEL', ...keys]);
      }
    } while (cursor != '0');
  }

  @override
  Future<void> close() async {
    _command.get_connection().close();
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

Future<CacheStore?> connectCacheStore(String? redisUrl) async {
  final url = redisUrl?.trim();
  if (url == null || url.isEmpty) {
    return null;
  }

  return RedisCacheStore.connect(url);
}

Future<Object?> decodeCachedJson(String? rawValue) async {
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  return jsonDecode(rawValue);
}

String encodeCachedJson(Object value) => jsonEncode(value);
