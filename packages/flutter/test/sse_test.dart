import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tbd_agents/tbd_agents.dart';

// ---------------------------------------------------------------------------
// Streaming mock HTTP client
// ---------------------------------------------------------------------------

typedef _Handler = Future<http.Response> Function(http.Request);

class _MockStreamClient extends http.BaseClient {
  _MockStreamClient(this._handler);

  final _Handler _handler;
  late http.Request lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest baseRequest) async {
    lastRequest = baseRequest as http.Request;
    final response = await _handler(lastRequest);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── iterSseMessages (synchronous line parser) ──────────────────────────────
  group('iterSseMessages – line parser', () {
    test('parses a single data event', () {
      final messages = iterSseMessages([
        'data: hello world',
        '',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals('hello world'));
      expect(messages[0].id, isNull);
      expect(messages[0].event, isNull);
    });

    test('parses id, event, retry, and data fields', () {
      final messages = iterSseMessages([
        'id: 42',
        'event: update',
        'retry: 3000',
        'data: payload',
        '',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].id, equals('42'));
      expect(messages[0].event, equals('update'));
      expect(messages[0].retry, equals(3000));
      expect(messages[0].data, equals('payload'));
    });

    test('skips comment lines (starting with :)', () {
      final messages = iterSseMessages([
        ': this is a comment',
        'data: real',
        '',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals('real'));
    });

    test('joins multi-line data with newlines', () {
      final messages = iterSseMessages([
        ': keepalive',
        'id: 1',
        r'data: {"id":1,',
        r'data: "type":"status"}',
        '',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].id, equals('1'));
      expect(messages[0].data, equals('{"id":1,\n"type":"status"}'));
    });

    test('parses multiple events separated by blank lines', () {
      final messages = iterSseMessages([
        'data: first',
        '',
        'data: second',
        '',
        'data: third',
        '',
      ]).toList();

      expect(messages, hasLength(3));
      expect(messages.map((m) => m.data).toList(),
          equals(['first', 'second', 'third']));
    });

    test('strips optional leading space from field value', () {
      final messages = iterSseMessages([
        'data: with leading space',
        '',
      ]).toList();

      expect(messages[0].data, equals('with leading space'));
    });

    test('handles field with no colon as field name with empty value', () {
      final messages = iterSseMessages([
        'data',
        '',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals(''));
    });

    test('flushes remaining event at end-of-stream without trailing blank line',
        () {
      final messages = iterSseMessages([
        'data: last',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals('last'));
    });

    test('ignores retry with non-integer value', () {
      final messages = iterSseMessages([
        'retry: not-a-number',
        'data: ok',
        '',
      ]).toList();

      expect(messages, hasLength(1));
      expect(messages[0].retry, isNull);
    });
  });

  // ── parseSseStream (async byte-stream parser) ─────────────────────────────
  group('parseSseStream – byte stream', () {
    Stream<List<int>> _bytes(String text) => Stream.value(utf8.encode(text));

    test('parses a single event from a byte stream', () async {
      final stream = _bytes('data: hello\n\n');
      final messages = await parseSseStream(stream).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals('hello'));
    });

    test('handles chunked delivery across multiple List<int> items', () async {
      const raw = 'id: 7\ndata: chunk\n\n';
      final chunked = raw.codeUnits.map((b) => [b]);
      final stream = Stream.fromIterable(chunked);

      final messages = await parseSseStream(stream).toList();
      expect(messages, hasLength(1));
      expect(messages[0].id, equals('7'));
      expect(messages[0].data, equals('chunk'));
    });

    test('parses multiple events from a byte stream', () async {
      const raw = 'data: one\n\ndata: two\n\ndata: three\n\n';
      final messages = await parseSseStream(_bytes(raw)).toList();

      expect(messages, hasLength(3));
      expect(messages.map((m) => m.data).toList(),
          equals(['one', 'two', 'three']));
    });

    test('skips comment-only blocks', () async {
      const raw = ': keepalive\n\ndata: real\n\n';
      final messages = await parseSseStream(_bytes(raw)).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals('real'));
    });

    test('handles CRLF line endings', () async {
      const raw = 'data: crlf\r\n\r\n';
      final messages = await parseSseStream(_bytes(raw)).toList();

      expect(messages, hasLength(1));
      expect(messages[0].data, equals('crlf'));
    });
  });

  // ── WorkflowsResource.stream integration ─────────────────────────────────
  group('WorkflowsResource.stream', () {
    test('yields WorkflowStreamEvent objects parsed from SSE frames', () async {
      const ssePayload = ': keepalive\n\n'
          'id: 8\n'
          'data: {"id":8,"type":"status","data":{"status":"running"},'
          '"timestamp":"2025-05-01T00:00:00Z"}\n\n'
          'id: 9\n'
          'data: {"id":9,"type":"message","data":{"content":"done"},'
          '"timestamp":"2025-05-01T00:00:01Z"}\n\n';

      final mock = _MockStreamClient((req) async {
        expect(req.url.path, equals('/api/workflows/wf_123/stream'));
        return http.Response(
          ssePayload,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'tok',
        httpClient: mock,
      );

      final events = await client.workflows.stream('wf_123').toList();
      client.close();

      expect(events, hasLength(2));
      expect(events[0].id, equals(8));
      expect(events[0].type, equals('status'));
      expect((events[0].data as Map)['status'], equals('running'));
      expect(events[1].id, equals(9));
      expect(events[1].type, equals('message'));
      expect((events[1].data as Map)['content'], equals('done'));
    });

    test('forwards Last-Event-ID header when lastEventId is provided',
        () async {
      final mock = _MockStreamClient((req) async {
        return http.Response(
          'data: {"id":10,"type":"ping","data":null,"timestamp":"2025-05-01T00:00:02Z"}\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'tok',
        httpClient: mock,
      );

      await client.workflows.stream('wf_123', lastEventId: 7).toList();
      client.close();

      expect(mock.lastRequest.headers['last-event-id'], equals('7'));
    });
  });
}
