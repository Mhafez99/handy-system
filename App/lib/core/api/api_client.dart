import 'dart:convert';

import 'package:handy_app/core/api/api_exception.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.accessToken,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;
  final String? accessToken;

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _get(path, queryParameters: queryParameters);
    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    }

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> getObject(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _get(path, queryParameters: queryParameters);
    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>> postObject(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('POST', path, body: body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<List<Map<String, dynamic>>> postList(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('POST', path, body: body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    }

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> postVoid(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('POST', path, body: body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> patchObject(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('PATCH', path, body: body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const ApiException('استجابة غير متوقعة من الخادم.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<void> putVoid(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('PUT', path, body: body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> deleteVoid(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _send('DELETE', path, body: body);

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<http.Response> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _send(
      'GET',
      path,
      queryParameters: queryParameters,
    );

    if (response.statusCode >= 400) {
      throw ApiException(
        _readErrorMessage(response.body) ?? 'تعذر الاتصال بالخادم.',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$normalizedBase$path').replace(
      queryParameters: queryParameters,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
    };

    final token = accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    return switch (method) {
      'POST' => await _httpClient.post(uri, headers: headers, body: encodedBody),
      'PUT' => await _httpClient.put(uri, headers: headers, body: encodedBody),
      'PATCH' => await _httpClient.patch(uri, headers: headers, body: encodedBody),
      'DELETE' => await _httpClient.delete(uri, headers: headers, body: encodedBody),
      _ => await _httpClient.get(uri, headers: headers),
    };
  }

  String? _readErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  void close() {
    _httpClient.close();
  }
}
