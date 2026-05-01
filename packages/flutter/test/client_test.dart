import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tbd_agents/tbd_agents.dart';

// ---------------------------------------------------------------------------
// Minimal mock HTTP client
// ---------------------------------------------------------------------------

typedef RequestHandler = Future<http.Response> Function(http.Request request);

class _MockClient extends http.BaseClient {
  _MockClient(this._handler);

  final RequestHandler _handler;
  final List<http.Request> seen = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest baseRequest) async {
    late http.Request request;
    if (baseRequest is http.Request) {
      request = baseRequest;
    } else {
      final bytes = await baseRequest.finalize().toBytes();
      request = http.Request(baseRequest.method, baseRequest.url)
        ..headers.addAll(baseRequest.headers)
        ..bodyBytes = bytes;
    }
    seen.add(request);
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

http.Response _jsonResponse(Object data, {int status = 200}) => http.Response(
      json.encode(data),
      status,
      headers: {'content-type': 'application/json'},
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── URL routing ────────────────────────────────────────────────────────────
  group('TbdAgentsClient – URL routing', () {
    test('health goes to /health (outside /api)', () async {
      late Uri captured;
      final mock = _MockClient((req) async {
        captured = req.url;
        return _jsonResponse({'status': 'ok'});
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );
      await client.health.get();
      client.close();

      expect(captured.path, equals('/health'));
    });

    test('API endpoints go to /api/{path}', () async {
      final paths = <String>[];
      final mock = _MockClient((req) async {
        paths.add(req.url.path);
        return _jsonResponse([]);
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );
      await client.agents.list();
      client.close();

      expect(paths, contains('/api/agents'));
    });

    test('trailing /api suffix in baseUrl is normalized', () async {
      final paths = <String>[];
      final mock = _MockClient((req) async {
        paths.add(req.url.path);
        if (req.url.path == '/health') return _jsonResponse({'status': 'ok'});
        return _jsonResponse([]);
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com/api',
        httpClient: mock,
      );
      await client.health.get();
      await client.agents.list();
      client.close();

      expect(paths, containsAll(['/health', '/api/agents']));
    });

    test('trailing slash in baseUrl is stripped', () async {
      late Uri captured;
      final mock = _MockClient((req) async {
        captured = req.url;
        return _jsonResponse([]);
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com/',
        httpClient: mock,
      );
      await client.agents.list();
      client.close();

      expect(captured.path, equals('/api/agents'));
      expect(captured.host, equals('example.com'));
    });
  });

  // ── Auth ───────────────────────────────────────────────────────────────────
  group('TbdAgentsClient – auth', () {
    test('sends Authorization header when token is set', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse({'status': 'ok'});
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'secret-token',
        httpClient: mock,
      );
      await client.health.get();
      client.close();

      expect(captured.headers['authorization'], equals('Bearer secret-token'));
    });

    test('trims whitespace from the token', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse([]);
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: '  trimmed-token  ',
        httpClient: mock,
      );
      await client.agents.list();
      client.close();

      expect(captured.headers['authorization'], equals('Bearer trimmed-token'));
    });

    test('omits Authorization header when no token is configured', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse({'status': 'ok'});
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );
      await client.health.get();
      client.close();

      expect(captured.headers.containsKey('authorization'), isFalse);
    });

    test('omits Authorization even when defaultHeaders contains it', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse({'status': 'ok'});
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        defaultHeaders: {'Authorization': 'Bearer should-be-ignored'},
        httpClient: mock,
      );
      await client.health.get();
      client.close();

      expect(captured.headers.containsKey('authorization'), isFalse);
    });

    test('omits Authorization header when token is blank', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse([]);
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: '   ',
        httpClient: mock,
      );
      await client.agents.list();
      client.close();

      expect(captured.headers.containsKey('authorization'), isFalse);
    });

    test('forwards custom defaultHeaders on every request', () async {
      final captured = <http.Request>[];
      final mock = _MockClient((req) async {
        captured.add(req);
        if (req.url.path == '/health') return _jsonResponse({'status': 'ok'});
        return _jsonResponse([]);
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'tok',
        defaultHeaders: {'x-custom': 'yes'},
        httpClient: mock,
      );
      await client.health.get();
      await client.agents.list();
      client.close();

      for (final req in captured) {
        expect(req.headers['x-custom'], equals('yes'));
      }
    });
  });

  // ── Request body ───────────────────────────────────────────────────────────
  group('TbdAgentsClient – request body', () {
    test('sends prompt as JSON body with correct content-type', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse({
          'workflow_id': 'wf_1',
          'status': 'running',
          'current_turn': 1,
          'max_turns': 10,
          'output_format': 'json',
          'logs': [],
          'messages': [],
        });
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'tok',
        httpClient: mock,
      );
      await client.workflows.sendPrompt('wf_1', prompt: 'hello');
      client.close();

      expect(captured.method, equals('POST'));
      expect(captured.url.path, equals('/api/workflows/wf_1/prompt'));
      expect(captured.headers['content-type'], contains('application/json'));
      final body = json.decode(captured.body) as Map<String, dynamic>;
      expect(body['prompt'], equals('hello'));
      expect(body.containsKey('request'), isFalse);
    });
  });

  // ── Multipart upload ───────────────────────────────────────────────────────
  group('TbdAgentsClient – multipart upload', () {
    test('sends multipart fields for knowledge item upload', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse({
          'id': 'ki_1',
          'source_id': 'ks_1',
          'name': 'hello.txt',
          'content_type': 'file',
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-01T00:00:00Z',
        });
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'tok',
        httpClient: mock,
      );
      final item = await client.knowledgeItems.upload(
        sourceId: 'ks_1',
        bytes: [1, 2, 3],
        filename: 'hello.txt',
        tags: ['docs', 'ops'],
        metadata: {'team': 'platform'},
      );
      client.close();

      expect(captured.method, equals('POST'));
      expect(captured.url.path, equals('/api/knowledge-items/upload'));
      expect(captured.headers['content-type'], contains('multipart/form-data'));

      final contentType = captured.headers['content-type']!;
      final boundary =
          RegExp(r'boundary=([^\s;]+)').firstMatch(contentType)?.group(1);
      expect(boundary, isNotNull);

      final bodyStr = String.fromCharCodes(captured.bodyBytes);
      expect(bodyStr, contains('source_id'));
      expect(bodyStr, contains('ks_1'));
      expect(bodyStr, contains('"docs"'));
      expect(bodyStr, contains('"platform"'));

      expect(item.id, equals('ki_1'));
      expect(item.sourceId, equals('ks_1'));
    });
  });

  // ── Error handling ─────────────────────────────────────────────────────────
  group('TbdAgentsClient – error handling', () {
    test('throws ApiException on 4xx response', () async {
      final mock = _MockClient((_) async => http.Response(
            json.encode({'detail': 'Not found'}),
            404,
            headers: {'content-type': 'application/json'},
          ));

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );

      await expectLater(
        client.agents.get('missing'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Not found'),
        ),
      );
      client.close();
    });

    test('rawRequest does NOT throw on 4xx', () async {
      final mock = _MockClient((_) async => http.Response('not found', 404));

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );
      final response = await client.rawRequest('GET', 'agents/x');
      client.close();

      expect(response.statusCode, equals(404));
    });
  });

  // ── Workflow polling ───────────────────────────────────────────────────────
  group('TbdAgentsClient – workflow polling', () {
    test('waitForCompletion polls until terminal last_task_status', () async {
      var callCount = 0;
      final mock = _MockClient((_) async {
        callCount++;
        final status = callCount < 2 ? 'running' : 'completed';
        return _jsonResponse({
          'id': 'wf_1',
          'agent_id': 'ag_1',
          'github_user': 'user',
          'model': 'gpt-4',
          'max_turns': 10,
          'current_turn': callCount,
          'status': 'active',
          'output_format': 'json',
          'skill_ids': [],
          'logs': [],
          'messages': [],
          'last_task_status': status,
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-01T00:00:00Z',
        });
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        token: 'tok',
        httpClient: mock,
      );
      final wf = await client.workflows.waitForCompletion(
        'wf_1',
        intervalMs: 0,
        timeoutMs: 5000,
      );
      client.close();

      expect(wf.lastTaskStatus, equals('completed'));
      expect(callCount, equals(2));
    });
  });

  // ── User-Agent ─────────────────────────────────────────────────────────────
  group('TbdAgentsClient – user agent', () {
    test('sends user-agent header with every request', () async {
      late http.Request captured;
      final mock = _MockClient((req) async {
        captured = req;
        return _jsonResponse({'status': 'ok'});
      });

      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );
      await client.health.get();
      client.close();

      expect(captured.headers['user-agent'], startsWith('tbd-agents-dart/'));
    });
  });
}
