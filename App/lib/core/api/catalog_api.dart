import 'package:handy_app/core/api/api_client.dart';

class CatalogApi {
  CatalogApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> loadCategories() {
    return _client.getList('/v1/catalog/categories');
  }

  Future<List<Map<String, dynamic>>> loadServices({required int categoryId}) {
    return _client.getList(
      '/v1/catalog/services',
      queryParameters: {'category_id': '$categoryId'},
    );
  }

  Future<List<Map<String, dynamic>>> loadAreas() {
    return _client.getList('/v1/catalog/areas');
  }
}
