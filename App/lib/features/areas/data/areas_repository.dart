import 'package:handy_app/features/areas/domain/area.dart';
import 'package:handy_app/core/api/catalog_api.dart';
import 'package:handy_app/core/api/handy_api.dart';
import 'package:handy_app/core/config/backend_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AreasRepository {
  AreasRepository({SupabaseClient? client, HandyApi? handyApi, CatalogApi? catalogApi})
    : _clientOverride = client,
      _handyApi = handyApi,
      _catalogApi = catalogApi;

  final SupabaseClient? _clientOverride;
  final HandyApi? _handyApi;
  final CatalogApi? _catalogApi;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  CatalogApi get _catalog {
    return _catalogApi ?? (_handyApi ?? HandyApi()).catalog;
  }

  Future<List<Area>> loadAreas() async {
    if (BackendConfig.isApiConfigured) {
      final rows = await _catalog.loadAreas();
      return rows.map((row) => Area.fromJson(row)).toList(growable: false);
    }

    final rows = await _client
        .from('areas')
        .select('id, governorate, name')
        .eq('is_active', true)
        .order('governorate')
        .order('sort_order')
        .order('name');

    return rows.map((row) => Area.fromJson(row)).toList(growable: false);
  }
}
