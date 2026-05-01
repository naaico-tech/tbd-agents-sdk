/// Base class for all resource helpers.
library;

import '../client.dart';

/// Provides access to the [TbdAgentsClient] for subclasses.
abstract class BaseResource {
  const BaseResource(this.client);

  /// The underlying SDK client.
  final TbdAgentsClient client;
}

/// Polls [fetcher] repeatedly until [predicate] returns `true` or [timeoutMs]
/// elapses.
///
/// Throws a [TimeoutException] when the timeout is reached.
Future<T> pollUntil<T>(
  Future<T> Function() fetcher, {
  bool Function(T)? predicate,
  int intervalMs = 1000,
  int timeoutMs = 60000,
}) async {
  final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (true) {
    final value = await fetcher();
    if (predicate == null || predicate(value)) return value;
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Polling timed out after ${timeoutMs}ms');
    }
    await Future<void>.delayed(Duration(milliseconds: intervalMs));
  }
}

/// Thrown by [pollUntil] when the deadline is exceeded.
class TimeoutException implements Exception {
  const TimeoutException(this.message);
  final String message;
  @override
  String toString() => 'TimeoutException: $message';
}
