/// Exceptions thrown by the TBD Agents SDK.
library;

/// Base class for all TBD Agents SDK exceptions.
class TbdAgentsException implements Exception {
  const TbdAgentsException(this.message);

  final String message;

  @override
  String toString() => 'TbdAgentsException: $message';
}

/// Thrown when the underlying HTTP transport fails (network error, timeout, etc.).
class TransportException extends TbdAgentsException {
  const TransportException(super.message, {this.cause});

  final Object? cause;

  @override
  String toString() =>
      cause == null ? 'TransportException: $message' : 'TransportException: $message (caused by $cause)';
}

/// Thrown when the API returns a non-2xx response.
class ApiException extends TbdAgentsException {
  const ApiException(
    super.message, {
    required this.statusCode,
    this.body,
  });

  /// HTTP status code returned by the server.
  final int statusCode;

  /// Parsed response body (may be a [Map], [List], [String], or `null`).
  final Object? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
