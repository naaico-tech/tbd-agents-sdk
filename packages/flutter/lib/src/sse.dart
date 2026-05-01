/// Server-Sent Events (SSE) parsing utilities.
library;

import 'dart:async';
import 'dart:convert';

/// A single SSE message parsed from an event stream.
class SseMessage {
  const SseMessage({
    required this.data,
    this.id,
    this.event,
    this.retry,
  });

  /// The concatenated `data` field value(s).
  final String data;

  /// The `id` field value, or `null` if absent.
  final String? id;

  /// The `event` field value, or `null` if absent.
  final String? event;

  /// The `retry` field value in milliseconds, or `null` if absent.
  final int? retry;

  @override
  String toString() => 'SseMessage(id: $id, event: $event, data: $data)';
}

/// Parses a stream of raw bytes from an SSE endpoint into [SseMessage] objects.
///
/// The [stream] should be the raw response body from the SSE endpoint (e.g.,
/// `response.stream` from `http.StreamedResponse`).
///
/// ```dart
/// final response = await client.send(request);
/// await for (final message in parseSseStream(response.stream)) {
///   print(message.data);
/// }
/// ```
Stream<SseMessage> parseSseStream(Stream<List<int>> stream) async* {
  final buffer = StringBuffer();
  final decoder = utf8.decoder;

  await for (final chunk in stream.transform(decoder)) {
    buffer.write(chunk);

    // Split on double-newline event separators.
    // We keep the last incomplete block in the buffer.
    var text = buffer.toString();
    buffer.clear();

    final blocks = text.split(RegExp(r'\r?\n\r?\n'));

    // The last element may be incomplete – keep it for the next iteration.
    final incomplete = blocks.removeLast();
    buffer.write(incomplete);

    for (final block in blocks) {
      final message = _parseBlock(block);
      if (message != null) yield message;
    }
  }

  // Flush any remaining content after the stream closes.
  final remaining = buffer.toString().trim();
  if (remaining.isNotEmpty) {
    final message = _parseBlock(remaining);
    if (message != null) yield message;
  }
}

/// Parses a sequence of text lines into [SseMessage] objects (iterator form).
///
/// Mirrors the Python `iter_sse_messages` API. Useful for testing with
/// pre-built line sequences.
Iterable<SseMessage> iterSseMessages(Iterable<String> lines) sync* {
  final dataLines = <String>[];
  String? eventName;
  String? eventId;
  int? retry;

  void reset() {
    dataLines.clear();
    eventName = null;
    eventId = null;
    retry = null;
  }

  SseMessage? flush() {
    if (dataLines.isEmpty && eventName == null && eventId == null && retry == null) {
      return null;
    }
    final msg = SseMessage(
      data: dataLines.join('\n'),
      id: eventId,
      event: eventName,
      retry: retry,
    );
    reset();
    return msg;
  }

  for (final rawLine in lines) {
    final line = rawLine.endsWith('\r') ? rawLine.substring(0, rawLine.length - 1) : rawLine;

    if (line.isEmpty) {
      final message = flush();
      if (message != null) yield message;
      continue;
    }

    // Skip comment lines.
    if (line.startsWith(':')) continue;

    final colonIndex = line.indexOf(':');
    late final String field;
    late final String value;

    if (colonIndex == -1) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colonIndex);
      final rawValue = line.substring(colonIndex + 1);
      value = rawValue.startsWith(' ') ? rawValue.substring(1) : rawValue;
    }

    switch (field) {
      case 'data':
        dataLines.add(value);
      case 'event':
        eventName = value;
      case 'id':
        eventId = value;
      case 'retry':
        retry = int.tryParse(value);
    }
  }

  final message = flush();
  if (message != null) yield message;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

SseMessage? _parseBlock(String block) {
  final lines = block.split(RegExp(r'\r?\n'));
  final dataLines = <String>[];
  String? id;
  String? event;
  int? retry;

  for (final line in lines) {
    if (line.isEmpty || line.startsWith(':')) continue;

    final colonIndex = line.indexOf(':');
    final String field;
    final String value;

    if (colonIndex == -1) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colonIndex);
      final rawValue = line.substring(colonIndex + 1);
      value = rawValue.startsWith(' ') ? rawValue.substring(1) : rawValue;
    }

    switch (field) {
      case 'data':
        dataLines.add(value);
      case 'event':
        event = value;
      case 'id':
        id = value;
      case 'retry':
        retry = int.tryParse(value);
    }
  }

  if (dataLines.isEmpty) return null;

  return SseMessage(
    data: dataLines.join('\n'),
    id: id,
    event: event,
    retry: retry,
  );
}
