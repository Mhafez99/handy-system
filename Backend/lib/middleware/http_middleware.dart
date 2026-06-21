import 'dart:convert';

import 'package:handy_backend/errors/request_action_exception.dart';
import 'package:shelf/shelf.dart';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}

Middleware jsonErrorMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (error) {
        return _jsonError(400, error.message);
      } on RequestActionException catch (error) {
        return _jsonError(400, error.message);
      } catch (error) {
        return _jsonError(500, 'Internal server error');
      }
    };
  };
}

Response jsonOk(Object? body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...corsHeaders,
    },
  );
}

Response jsonRateLimit({
  required int retryAfterSeconds,
  required int limit,
}) {
  return Response(
    429,
    body: jsonEncode({'error': 'Too many requests'}),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Retry-After': '$retryAfterSeconds',
      'X-RateLimit-Limit': '$limit',
      'X-RateLimit-Remaining': '0',
      ...corsHeaders,
    },
  );
}

Response jsonError(int statusCode, String message) {
  return _jsonError(statusCode, message);
}

Response _jsonError(int statusCode, String message) {
  return Response(
    statusCode,
    body: jsonEncode({'error': message}),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...corsHeaders,
    },
  );
}

Future<Map<String, dynamic>> readJsonBody(Request request) async {
  final rawBody = await request.readAsString();
  if (rawBody.trim().isEmpty) {
    return {};
  }

  final decoded = jsonDecode(rawBody);
  if (decoded is! Map) {
    throw const FormatException('Invalid JSON body');
  }

  return Map<String, dynamic>.from(decoded);
}
