import 'dart:convert';

import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:http/http.dart' as http;

class SignedUploadUrl {
  const SignedUploadUrl({
    required this.uploadUrl,
    required this.token,
  });

  final String uploadUrl;
  final String token;
}

class SupabaseStorageClient {
  SupabaseStorageClient({
    required String supabaseUrl,
    required String serviceRoleKey,
    http.Client? httpClient,
  }) : _supabaseUrl = supabaseUrl.endsWith('/')
           ? supabaseUrl.substring(0, supabaseUrl.length - 1)
           : supabaseUrl,
       _serviceRoleKey = serviceRoleKey,
       _httpClient = httpClient ?? http.Client();

  final String _supabaseUrl;
  final String _serviceRoleKey;
  final http.Client _httpClient;

  static const requestImagesBucket = 'request-images';

  Future<SignedUploadUrl> createSignedUploadUrl({
    required String objectPath,
    int expiresIn = 600,
  }) async {
    final encodedPath = objectPath.split('/').map(Uri.encodeComponent).join('/');
    final uri = Uri.parse(
      '$_supabaseUrl/storage/v1/object/upload/sign/$requestImagesBucket/$encodedPath',
    );

    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: jsonEncode({'expiresIn': expiresIn}),
    );

    if (response.statusCode >= 400) {
      throw RequestActionException(
        'Unable to create upload URL (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const RequestActionException('Invalid upload URL response');
    }

    final uploadUrl = decoded['url'] as String?;
    final token = decoded['token'] as String?;
    if (uploadUrl == null || token == null) {
      throw const RequestActionException('Invalid upload URL response');
    }

    return SignedUploadUrl(uploadUrl: uploadUrl, token: token);
  }

  Future<String> createSignedReadUrl({
    required String objectPath,
    int expiresIn = 3600,
  }) async {
    final encodedPath = objectPath.split('/').map(Uri.encodeComponent).join('/');
    final uri = Uri.parse(
      '$_supabaseUrl/storage/v1/object/sign/$requestImagesBucket/$encodedPath',
    );

    final response = await _httpClient.post(
      uri,
      headers: _headers,
      body: jsonEncode({'expiresIn': expiresIn}),
    );

    if (response.statusCode >= 400) {
      throw RequestActionException(
        'Unable to create read URL (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const RequestActionException('Invalid read URL response');
    }

    final signedUrl = decoded['signedURL'] ?? decoded['signedUrl'];
    if (signedUrl is! String || signedUrl.isEmpty) {
      throw const RequestActionException('Invalid read URL response');
    }

    if (signedUrl.startsWith('http')) {
      return signedUrl;
    }

    return '$_supabaseUrl/storage/v1$signedUrl';
  }

  Map<String, String> get _headers => {
    'apikey': _serviceRoleKey,
    'Authorization': 'Bearer $_serviceRoleKey',
    'Content-Type': 'application/json',
  };

  void close() {
    _httpClient.close();
  }
}
