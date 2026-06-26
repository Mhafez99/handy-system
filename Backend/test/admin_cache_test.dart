import 'dart:convert';

import 'package:handy_backend/cache/cache_store.dart';
import 'package:handy_backend/repositories/admin_repository.dart';
import 'package:test/support/throwing_database.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryCacheStore', () {
    late InMemoryCacheStore cache;

    setUp(() {
      cache = InMemoryCacheStore();
    });

    test('stores and returns values before ttl expires', () async {
      await cache.set(
        key: 'key-1',
        value: 'value-1',
        ttl: const Duration(minutes: 1),
      );

      expect(await cache.get('key-1'), 'value-1');
    });

    test('expires values after ttl', () async {
      await cache.set(
        key: 'key-1',
        value: 'value-1',
        ttl: Duration.zero,
      );

      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(await cache.get('key-1'), isNull);
    });

    test('deleteByPrefix removes matching keys only', () async {
      await cache.set(
        key: 'admin:overview:stats:all:all',
        value: 'stats',
        ttl: const Duration(minutes: 1),
      );
      await cache.set(
        key: 'admin:overview:trend:all:all',
        value: 'trend',
        ttl: const Duration(minutes: 1),
      );
      await cache.set(
        key: 'other:key',
        value: 'other',
        ttl: const Duration(minutes: 1),
      );

      await cache.deleteByPrefix('admin:overview:');

      expect(await cache.get('admin:overview:stats:all:all'), isNull);
      expect(await cache.get('admin:overview:trend:all:all'), isNull);
      expect(await cache.get('other:key'), 'other');
    });
  });

  group('AdminRepository overview cache', () {
    test('returns cached stats without querying database', () async {
      final cache = InMemoryCacheStore();
      await cache.set(
        key: 'admin:overview:stats:all:all',
        value: jsonEncode({'total_requests': 42, 'is_filtered': false}),
        ttl: const Duration(minutes: 1),
      );

      final repository = AdminRepository(
        ThrowingDatabase(),
        cache: cache,
      );

      final stats = await repository.getOverviewStats();
      expect(stats['total_requests'], 42);
    });

    test('returns cached trend without querying database', () async {
      final cache = InMemoryCacheStore();
      await cache.set(
        key: 'admin:overview:trend:all:all',
        value: jsonEncode([
          {'day': '2026-06-01', 'total': 7, 'completed': 3},
        ]),
        ttl: const Duration(minutes: 1),
      );

      final repository = AdminRepository(
        ThrowingDatabase(),
        cache: cache,
      );

      final trend = await repository.getOverviewDailyTrend();
      expect(trend, hasLength(1));
      expect(trend.first['total'], 7);
    });
  });
}
