import 'dart:convert';

import 'package:http/http.dart' as http;

class FcmMessage {
  const FcmMessage({
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String title;
  final String body;
  final Map<String, String> data;
}

class FcmClient {
  FcmClient({
    required String serverKey,
    http.Client? httpClient,
  }) : _serverKey = serverKey,
       _httpClient = httpClient ?? http.Client();

  final String _serverKey;
  final http.Client _httpClient;

  Future<FcmSendResult> send({
    required String token,
    required FcmMessage message,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Authorization': 'key=$_serverKey',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': message.title,
          'body': message.body,
        },
        'data': message.data,
        'priority': 'high',
      }),
    );

    if (response.statusCode >= 400) {
      return FcmSendResult.failed;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return FcmSendResult.failed;
      }

      final failure = decoded['failure'];
      final results = decoded['results'];
      if (failure is int && failure > 0 && results is List && results.isNotEmpty) {
        final first = results.first;
        if (first is Map) {
          final error = first['error'];
          if (error == 'NotRegistered' || error == 'InvalidRegistration') {
            return FcmSendResult.invalidToken;
          }
        }
      }

      return FcmSendResult.sent;
    } catch (_) {
      return FcmSendResult.failed;
    }
  }

  void close() {
    _httpClient.close();
  }
}

enum FcmSendResult {
  sent,
  invalidToken,
  failed,
}
