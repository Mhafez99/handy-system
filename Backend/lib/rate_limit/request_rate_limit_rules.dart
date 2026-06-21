import 'package:shelf/shelf.dart';

class RateLimitRule {
  const RateLimitRule({
    required this.name,
    required this.matches,
    required this.limit,
    required this.window,
  });

  final String name;
  final bool Function(Request request) matches;
  final int limit;
  final Duration window;
}

String normalizeRequestPath(Request request) {
  var path = request.url.path;
  if (path.isEmpty) {
    path = '/';
  } else if (!path.startsWith('/')) {
    path = '/$path';
  }
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

bool _isCreateRequest(Request request) {
  if (request.method != 'POST') {
    return false;
  }

  final path = normalizeRequestPath(request);
  return path == '/' || path == '/v1/requests';
}

bool _isAvailableRequests(Request request) {
  if (request.method != 'GET') {
    return false;
  }

  final path = normalizeRequestPath(request);
  return path == '/available' || path.endsWith('/available');
}

bool _isCreateOffer(Request request) {
  if (request.method != 'POST') {
    return false;
  }

  final path = normalizeRequestPath(request);
  return RegExp(r'^(?:/v1/requests)?/[^/]+/offers$').hasMatch(path);
}

const requestRateLimitRules = <RateLimitRule>[
  RateLimitRule(
    name: 'create_request',
    matches: _isCreateRequest,
    limit: 10,
    window: Duration(hours: 1),
  ),
  RateLimitRule(
    name: 'create_offer',
    matches: _isCreateOffer,
    limit: 30,
    window: Duration(hours: 1),
  ),
  RateLimitRule(
    name: 'available_requests',
    matches: _isAvailableRequests,
    limit: 60,
    window: Duration(minutes: 1),
  ),
];
