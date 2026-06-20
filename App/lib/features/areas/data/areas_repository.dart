import 'package:handy_app/features/areas/domain/area.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AreasRepository {
  AreasRepository({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client {
    return _clientOverride ?? Supabase.instance.client;
  }

  Future<List<Area>> loadAreas() async {
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
