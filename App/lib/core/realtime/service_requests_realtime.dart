import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceRequestsRealtime {
  ServiceRequestsRealtime({SupabaseClient? client}) : _clientOverride = client;

  final SupabaseClient? _clientOverride;
  RealtimeChannel? _channel;

  SupabaseClient? _resolveClient() {
    if (_clientOverride != null) {
      return _clientOverride;
    }

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void subscribeToChanges({
    required VoidCallback onChange,
    String? channelName,
  }) {
    final client = _resolveClient();
    if (client == null) {
      return;
    }

    unsubscribe();
    _channel = client
        .channel(
          channelName ??
              'service-requests-${DateTime.now().microsecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_requests',
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'offers',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  void subscribeToRequest({
    required String requestId,
    required VoidCallback onChange,
  }) {
    final client = _resolveClient();
    if (client == null) {
      return;
    }

    unsubscribe();
    _channel = client
        .channel('request-$requestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: requestId,
          ),
          callback: (_) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'offers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'request_id',
            value: requestId,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  Future<void> unsubscribe() async {
    final channel = _channel;
    final client = _resolveClient();
    if (channel == null || client == null) {
      _channel = null;
      return;
    }

    await client.removeChannel(channel);
    _channel = null;
  }
}
