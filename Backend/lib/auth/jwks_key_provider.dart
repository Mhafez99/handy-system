import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// Fetches and caches Supabase asymmetric signing keys from a JWKS endpoint.
///
/// Supabase's new API key system signs access tokens with rotating asymmetric
/// keys (ES256/RS256). Public keys are published at the project's
/// `/auth/v1/.well-known/jwks.json` endpoint and are matched to a token via the
/// `kid` header claim.
class JwksKeyProvider {
  JwksKeyProvider(
    this.jwksUrl, {
    http.Client? httpClient,
    Duration cacheTtl = const Duration(minutes: 10),
  })  : _httpClient = httpClient ?? http.Client(),
        _cacheTtl = cacheTtl;

  final String jwksUrl;
  final http.Client _httpClient;
  final Duration _cacheTtl;

  Map<String, JWTKey> _keys = {};
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _inflight;

  bool get _isStale => DateTime.now().difference(_lastFetch) > _cacheTtl;

  /// Returns the key matching [kid]. Refreshes the cache when the key is
  /// unknown or the cache is stale. When [kid] is null and only a single key is
  /// published, that key is returned as a fallback.
  Future<JWTKey?> keyForKid(String? kid) async {
    if (kid != null && _keys.containsKey(kid) && !_isStale) {
      return _keys[kid];
    }

    if (_isStale || (kid != null && !_keys.containsKey(kid))) {
      await _refresh();
    }

    if (kid == null) {
      return _keys.values.length == 1 ? _keys.values.first : null;
    }

    return _keys[kid];
  }

  Future<void> _refresh() {
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  Future<void> _fetch() async {
    final response = await _httpClient.get(Uri.parse(jwksUrl));
    if (response.statusCode >= 400) {
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['keys'] is! List) {
      return;
    }

    final parsed = <String, JWTKey>{};
    for (final entry in decoded['keys'] as List) {
      if (entry is! Map) {
        continue;
      }

      final jwk = Map<String, dynamic>.from(entry);
      final kid = jwk['kid'];
      if (kid is! String || kid.isEmpty) {
        continue;
      }

      try {
        parsed[kid] = JWTKey.fromJWK(jwk);
      } catch (_) {
        // Skip keys we cannot parse (unsupported curve/type).
      }
    }

    if (parsed.isNotEmpty) {
      _keys = parsed;
      _lastFetch = DateTime.now();
    }
  }

  void close() {
    _httpClient.close();
  }
}
