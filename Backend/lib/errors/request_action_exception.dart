class RequestActionException implements Exception {
  const RequestActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
