import 'package:postgres/postgres.dart';
import 'package:handy_backend/db/database.dart';

class CatalogRepository {
  CatalogRepository(this._database);

  final Database _database;

  Future<List<Map<String, Object?>>> listCategories() async {
    final connection = await _database.connect();
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
  }

  Future<List<Map<String, Object?>>> listServices({int? categoryId}) async {
    final connection = await _database.connect();
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
  }

  Future<List<Map<String, Object?>>> listAreas() async {
    final connection = await _database.connect();
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
  }
}
