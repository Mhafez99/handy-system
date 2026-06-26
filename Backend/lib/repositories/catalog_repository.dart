import 'dart:convert';

import 'package:handy_backend/cache/cache_store.dart';
import 'package:handy_backend/db/database.dart';
import 'package:postgres/postgres.dart';

class CatalogRepository {
  CatalogRepository(
    this._database, {
    CacheStore? cache,
    Duration cacheTtl = const Duration(minutes: 5),
  }) : _cache = cache,
       _cacheTtl = cacheTtl;

  final Database _database;
  final CacheStore? _cache;
  final Duration _cacheTtl;

  static const _cachePrefix = 'catalog:';

  Future<List<Map<String, Object?>>> listCategories() {
    return _readCachedList(
      '${_cachePrefix}categories',
      () => _database.withReadConnection((connection) async {
        final result = await connection.execute(
          Sql.named('''
            select id, name
            from public.categories
            where is_active = true
            order by sort_order, name
          '''),
        );

        return result
            .map(
              (row) => {
                'id': row[0],
                'name': row[1],
              },
            )
            .toList(growable: false);
      }),
    );
  }

  Future<List<Map<String, Object?>>> listServices({int? categoryId}) {
    final cacheKey = '${_cachePrefix}services:${categoryId ?? 'all'}';
    return _readCachedList(
      cacheKey,
      () => _database.withReadConnection((connection) async {
        final result = await connection.execute(
          Sql.named('''
            select id, category_id, name, min_price, max_price
            from public.services
            where is_active = true
              and (@categoryId::bigint is null or category_id = @categoryId)
            order by name
          '''),
          parameters: {'categoryId': categoryId},
        );

        return result
            .map(
              (row) => {
                'id': row[0],
                'category_id': row[1],
                'name': row[2],
                'min_price': row[3],
                'max_price': row[4],
              },
            )
            .toList(growable: false);
      }),
    );
  }

  Future<List<Map<String, Object?>>> listAreas() {
    return _readCachedList(
      '${_cachePrefix}areas',
      () => _database.withReadConnection((connection) async {
        final result = await connection.execute(
          Sql.named('''
            select id, governorate, name
            from public.areas
            where is_active = true
            order by governorate, sort_order, name
          '''),
        );

        return result
            .map(
              (row) => {
                'id': row[0],
                'governorate': row[1],
                'name': row[2],
              },
            )
            .toList(growable: false);
      }),
    );
  }

  Future<List<Map<String, Object?>>> _readCachedList(
    String cacheKey,
    Future<List<Map<String, Object?>>> Function() loader,
  ) async {
    final cache = _cache;
    if (cache != null) {
      final raw = await cache.get(cacheKey);
      final decoded = await decodeCachedJson(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false);
      }
    }

    final value = await loader();
    if (cache != null) {
      await cache.set(
        key: cacheKey,
        value: encodeCachedJson(value),
        ttl: _cacheTtl,
      );
    }

    return value;
  }
}
