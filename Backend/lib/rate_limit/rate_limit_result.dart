class RateLimitResult {
  const RateLimitResult({
    required this.allowed,
    required this.limit,
    required this.remaining,
    required this.retryAfterSeconds,
  });

  final bool allowed;
  final int limit;
  final int remaining;
  final int retryAfterSeconds;

  factory RateLimitResult.allowed({
    required int limit,
    required int count,
  }) {
    return RateLimitResult(
      allowed: true,
      limit: limit,
      remaining: count >= limit ? 0 : limit - count,
      retryAfterSeconds: 0,
    );
  }

  factory RateLimitResult.denied({
    required int limit,
    required int retryAfterSeconds,
  }) {
    return RateLimitResult(
      allowed: false,
      limit: limit,
      remaining: 0,
      retryAfterSeconds: retryAfterSeconds,
    );
  }
}
