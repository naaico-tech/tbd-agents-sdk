import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tbd_agents/tbd_agents.dart';
import 'package:tbd_agents/src/resources/base.dart' as base;

typedef RequestHandler = Future<http.Response> Function(http.Request request);

class _RecordingClient extends http.BaseClient {
  _RecordingClient(this._handler);

  final RequestHandler _handler;
  final List<http.Request> seen = [];
  bool closed = false;

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
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}

http.Response _jsonResponse(Object data, {int status = 200}) => http.Response(
      json.encode(data),
      status,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _workflowJson({
  String id = 'wf_1',
  String lastTaskStatus = 'running',
}) =>
    {
      'id': id,
      'agent_id': 'agent_1',
      'github_user': 'octocat',
      'model': 'gpt-5',
      'max_turns': 6,
      'current_turn': 1,
      'status': 'active',
      'output_format': 'json',
      'skill_ids': ['skill_1'],
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:01Z',
      'last_task_status': lastTaskStatus,
      'logs': const [],
      'messages': const [],
    };

Map<String, dynamic> _taskJson({
  String id = 'task_1',
  String status = 'running',
}) =>
    {
      'id': id,
      'workflow_id': 'wf_1',
      'prompt': 'run tests',
      'status': status,
      'tool_calls': 1,
      'created_at': '2025-01-01T00:00:00Z',
      'logs': const [],
      'messages': const [],
    };

Map<String, dynamic> _knowledgeItemJson({String id = 'ki_1'}) => {
      'id': id,
      'source_id': 'ks_1',
      'name': 'hello.txt',
      'content_type': 'file',
      'created_at': '2025-01-01T00:00:00Z',
      'updated_at': '2025-01-01T00:00:01Z',
    };

void main() {
  group('resource helpers', () {
    test(
        'pollUntil returns matching values and times out with custom exception',
        () async {
      var attempts = 0;
      final result = await base.pollUntil<int>(
        () async => ++attempts,
        predicate: (value) => value == 2,
        intervalMs: 0,
        timeoutMs: 50,
      );

      expect(result, 2);

      await expectLater(
        () => base.pollUntil<int>(
          () async => 1,
          predicate: (value) => value == 2,
          intervalMs: 0,
          timeoutMs: 0,
        ),
        throwsA(
          isA<base.TimeoutException>().having(
            (error) => error.toString(),
            'toString',
            contains('Polling timed out after 0ms'),
          ),
        ),
      );
    });

    test('CollectionResource performs CRUD operations', () async {
      final mock = _RecordingClient((request) async {
        switch ('${request.method} ${request.url.path}') {
          case 'GET /api/widgets':
            return _jsonResponse([
              {'id': 'widget_1'},
              'ignored',
            ]);
          case 'GET /api/widgets/widget_1':
            return _jsonResponse({'id': 'widget_1'});
          case 'POST /api/widgets':
            return _jsonResponse(json.decode(request.body));
          case 'PUT /api/widgets/widget_1':
            return _jsonResponse(json.decode(request.body));
          case 'DELETE /api/widgets/widget_1':
            return http.Response('', 204);
        }
        throw StateError(
            'Unexpected request: ${request.method} ${request.url}');
      });
      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );
      final resource = CollectionResource(client, 'widgets');

      expect(await resource.list(), [
        {'id': 'widget_1'},
      ]);
      expect(await resource.get('widget_1'), {'id': 'widget_1'});
      expect(await resource.create({'name': 'new'}), {'name': 'new'});
      expect(await resource.update('widget_1', {'name': 'updated'}),
          {'name': 'updated'});
      await resource.delete('widget_1');
      client.close();

      expect(mock.closed, isFalse);
    });
  });

  group('simple map resources', () {
    test(
        'agents, skills, mcps, providers, tokens, models, and knowledge sources route correctly',
        () async {
      final mock = _RecordingClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path == '/api/agents' && method == 'GET') {
          return _jsonResponse([
            {'id': 'agent_1'},
            1,
          ]);
        }
        if (path == '/api/agents/agent_1' && method == 'GET') {
          return _jsonResponse({'id': 'agent_1'});
        }
        if (path == '/api/agents' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/agents/agent_1' && method == 'PUT') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/agents/agent_1' && method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path == '/api/agents/export' && method == 'GET') {
          return _jsonResponse({'scope': 'all'});
        }
        if (path == '/api/agents/agent_1/export' && method == 'GET') {
          return _jsonResponse({'scope': 'single'});
        }
        if (path == '/api/agents/import' && method == 'POST') {
          return _jsonResponse({'imported': true});
        }

        if (path == '/api/skills' && method == 'GET') {
          return _jsonResponse('not-a-list');
        }
        if (path == '/api/skills/skill_1' && method == 'GET') {
          return _jsonResponse({'id': 'skill_1'});
        }
        if (path == '/api/skills' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/skills/skill_1' && method == 'PUT') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/skills/skill_1' && method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path == '/api/skills/export' && method == 'GET') {
          return _jsonResponse({'scope': 'all'});
        }
        if (path == '/api/skills/skill_1/export' && method == 'GET') {
          return _jsonResponse({'scope': 'single'});
        }
        if (path == '/api/skills/import' && method == 'POST') {
          return _jsonResponse({'imported': true});
        }

        if (path == '/api/mcps' && method == 'GET') {
          return _jsonResponse([
            {'id': 'mcp_1'},
          ]);
        }
        if (path == '/api/mcps/mcp_1' && method == 'GET') {
          return _jsonResponse({'id': 'mcp_1'});
        }
        if (path == '/api/mcps' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/mcps/mcp_1' && method == 'PUT') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/mcps/mcp_1' && method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path == '/api/mcps/mcp_1/test' && method == 'POST') {
          return _jsonResponse({'ok': true});
        }
        if (path == '/api/mcps/mcp_1/tools' && method == 'GET') {
          return _jsonResponse({
            'tools': ['read']
          });
        }

        if (path == '/api/providers' && method == 'GET') {
          return _jsonResponse([
            {'id': 'provider_1'},
          ]);
        }
        if (path == '/api/providers/provider_1' && method == 'GET') {
          return _jsonResponse({'id': 'provider_1'});
        }
        if (path == '/api/providers' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/providers/provider_1' && method == 'PUT') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/providers/provider_1' && method == 'DELETE') {
          return http.Response('', 204);
        }

        if (path == '/api/tokens' && method == 'GET') {
          return _jsonResponse([
            {'id': 'token_1'},
          ]);
        }
        if (path == '/api/tokens/token_1' && method == 'GET') {
          return _jsonResponse({'id': 'token_1'});
        }
        if (path == '/api/tokens' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/tokens/token_1' && method == 'PUT') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/tokens/token_1' && method == 'DELETE') {
          return http.Response('', 204);
        }

        if (path == '/api/models' && method == 'GET') {
          return _jsonResponse([
            {'id': 'model_1'},
          ]);
        }
        if (path == '/api/models/model_1' && method == 'GET') {
          return _jsonResponse({'id': 'model_1'});
        }

        if (path == '/api/knowledge-sources' && method == 'GET') {
          return _jsonResponse([
            {'id': 'source_1'},
          ]);
        }
        if (path == '/api/knowledge-sources/source_1' && method == 'GET') {
          return _jsonResponse({'id': 'source_1'});
        }
        if (path == '/api/knowledge-sources' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/knowledge-sources/source_1' && method == 'PUT') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/knowledge-sources/source_1' && method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path == '/api/knowledge-sources/source_1/test' &&
            method == 'POST') {
          return _jsonResponse({'status': 'ok'});
        }
        if (path == '/api/knowledge-sources/export' && method == 'GET') {
          return _jsonResponse({'scope': 'all'});
        }
        if (path == '/api/knowledge-sources/source_1/export' &&
            method == 'GET') {
          return _jsonResponse({'scope': 'single'});
        }
        if (path == '/api/knowledge-sources/import' && method == 'POST') {
          return _jsonResponse({'imported': true});
        }

        throw StateError(
            'Unexpected request: ${request.method} ${request.url}');
      });
      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );

      expect(client.knowledge_sources, same(client.knowledgeSources));
      expect(client.knowledge_items, same(client.knowledgeItems));

      expect(await client.agents.list(), [
        {'id': 'agent_1'},
      ]);
      expect(await client.agents.get('agent_1'), {'id': 'agent_1'});
      expect(await client.agents.create({'name': 'agent'}), {'name': 'agent'});
      expect(await client.agents.update('agent_1', {'name': 'updated'}),
          {'name': 'updated'});
      await client.agents.delete('agent_1');
      expect(await client.agents.export(), {'scope': 'all'});
      expect(
          await client.agents.export(agentId: 'agent_1'), {'scope': 'single'});
      expect(await client.agents.import_({'name': 'imported'}),
          {'imported': true});

      expect(await client.skills.list(), isEmpty);
      expect(await client.skills.get('skill_1'), {'id': 'skill_1'});
      expect(await client.skills.create({'name': 'skill'}), {'name': 'skill'});
      expect(await client.skills.update('skill_1', {'name': 'updated'}),
          {'name': 'updated'});
      await client.skills.delete('skill_1');
      expect(await client.skills.export(), {'scope': 'all'});
      expect(
          await client.skills.export(skillId: 'skill_1'), {'scope': 'single'});
      expect(await client.skills.import_({'name': 'imported'}),
          {'imported': true});

      expect((await client.mcps.list()).single['id'], 'mcp_1');
      expect(await client.mcps.get('mcp_1'), {'id': 'mcp_1'});
      expect(await client.mcps.create({'name': 'mcp'}), {'name': 'mcp'});
      expect(await client.mcps.update('mcp_1', {'name': 'updated'}),
          {'name': 'updated'});
      await client.mcps.delete('mcp_1');
      expect(await client.mcps.test('mcp_1'), {'ok': true});
      expect(await client.mcps.tools('mcp_1'), {
        'tools': ['read'],
      });

      expect((await client.providers.list()).single['id'], 'provider_1');
      expect(await client.providers.get('provider_1'), {'id': 'provider_1'});
      expect(await client.providers.create({'name': 'provider'}),
          {'name': 'provider'});
      expect(await client.providers.update('provider_1', {'name': 'updated'}),
          {'name': 'updated'});
      await client.providers.delete('provider_1');

      expect((await client.tokens.list()).single['id'], 'token_1');
      expect(await client.tokens.get('token_1'), {'id': 'token_1'});
      expect(await client.tokens.create({'name': 'token'}), {'name': 'token'});
      expect(await client.tokens.update('token_1', {'name': 'updated'}),
          {'name': 'updated'});
      await client.tokens.delete('token_1');

      expect((await client.models.list()).single['id'], 'model_1');
      expect(await client.models.get('model_1'), {'id': 'model_1'});

      expect((await client.knowledgeSources.list()).single['id'], 'source_1');
      expect(await client.knowledgeSources.get('source_1'), {'id': 'source_1'});
      expect(await client.knowledgeSources.create({'name': 'source'}),
          {'name': 'source'});
      expect(
          await client.knowledgeSources.update('source_1', {'name': 'updated'}),
          {'name': 'updated'});
      await client.knowledgeSources.delete('source_1');
      expect(await client.knowledgeSources.test('source_1'), {'status': 'ok'});
      expect(await client.knowledgeSources.export(), {'scope': 'all'});
      expect(
        await client.knowledgeSources.export(sourceId: 'source_1'),
        {'scope': 'single'},
      );
      expect(
        await client.knowledgeSources.import_({'name': 'imported'}),
        {'imported': true},
      );
      client.close();
    });
  });

  group('typed resources', () {
    test(
        'knowledge items, tasks, and workflows map server responses into models',
        () async {
      var taskGetCalls = 0;
      var workflowGetCalls = 0;
      final mock = _RecordingClient((request) async {
        final path = request.url.path;
        final method = request.method;

        if (path == '/api/knowledge-items' && method == 'GET') {
          if (request.url.queryParameters.isEmpty) {
            return _jsonResponse('not-a-list');
          }
          expect(request.url.queryParameters, {
            'source_id': 'ks_1',
            'tags': 'docs,api',
            'content_type': 'file',
          });
          return _jsonResponse([
            _knowledgeItemJson(),
          ]);
        }
        if (path == '/api/knowledge-items/ki_1' && method == 'GET') {
          return _jsonResponse(_knowledgeItemJson());
        }
        if (path == '/api/knowledge-items' && method == 'POST') {
          return _jsonResponse(_knowledgeItemJson());
        }
        if (path == '/api/knowledge-items/ki_1' && method == 'PUT') {
          return _jsonResponse(_knowledgeItemJson());
        }
        if (path == '/api/knowledge-items/ki_1' && method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path == '/api/knowledge-items/query' && method == 'POST') {
          return _jsonResponse(json.decode(request.body));
        }
        if (path == '/api/knowledge-items/ki_1/content' && method == 'GET') {
          return http.Response.bytes(
            [1, 2, 3],
            200,
            headers: {
              'content-type': 'text/plain',
              'content-disposition': 'attachment; filename="notes.txt"',
            },
          );
        }
        if (path == '/api/knowledge-items/ki_2/content' && method == 'GET') {
          return http.Response('nope', 500);
        }

        if (path == '/api/tasks' && method == 'GET') {
          return _jsonResponse([
            _taskJson(),
          ]);
        }
        if (path == '/api/tasks/task_1' && method == 'GET') {
          taskGetCalls++;
          return _jsonResponse(
            _taskJson(
              status: taskGetCalls == 1 ? 'running' : 'completed',
            ),
          );
        }
        if (path == '/api/tasks/task_1' && method == 'DELETE') {
          return http.Response('', 204);
        }

        if (path == '/api/workflows' && method == 'GET') {
          return _jsonResponse([
            _workflowJson(),
          ]);
        }
        if (path == '/api/workflows/wf_1' && method == 'GET') {
          workflowGetCalls++;
          return _jsonResponse(
            _workflowJson(
              lastTaskStatus: workflowGetCalls == 1 ? 'running' : 'completed',
            ),
          );
        }
        if (path == '/api/workflows' && method == 'POST') {
          return _jsonResponse(_workflowJson(id: 'wf_created'));
        }
        if (path == '/api/workflows/wf_1' && method == 'PUT') {
          return _jsonResponse(_workflowJson(id: 'wf_updated'));
        }
        if (path == '/api/workflows/wf_1' && method == 'DELETE') {
          return http.Response('', 204);
        }
        if (path == '/api/workflows/export' && method == 'GET') {
          return _jsonResponse({'scope': 'all'});
        }
        if (path == '/api/workflows/wf_1/export' && method == 'GET') {
          return _jsonResponse({'scope': 'single'});
        }
        if (path == '/api/workflows/import' && method == 'POST') {
          return _jsonResponse({'imported': true});
        }
        if (path == '/api/workflows/wf_1/prompt' && method == 'POST') {
          expect(json.decode(request.body), {
            'request': {'prompt': 'hello'},
            'reasoning_effort': 'high',
          });
          return _jsonResponse({
            'workflow_id': 'wf_1',
            'status': 'running',
            'current_turn': 2,
            'max_turns': 6,
            'output_format': 'json',
            'messages': const [],
            'logs': const [],
          });
        }
        if (path == '/api/workflows/wf_1/halt' && method == 'POST') {
          return _jsonResponse({'detail': 'halted'});
        }
        if (path == '/api/workflows/wf_1/skills/skill_1' && method == 'POST') {
          return _jsonResponse(_workflowJson(id: 'wf_installed'));
        }
        if (path == '/api/workflows/wf_1/skills/skill_1' &&
            method == 'DELETE') {
          return _jsonResponse(_workflowJson(id: 'wf_removed'));
        }
        if (path == '/api/tasks/workflow/wf_1' && method == 'GET') {
          return _jsonResponse([
            _taskJson(id: 'task_2', status: 'completed'),
          ]);
        }
        if (path == '/api/workflows/wf_stream/stream' && method == 'GET') {
          return http.Response(
            'data: not-json\n\n'
            'data: {"id":1,"type":"status","data":{"state":"running"},"timestamp":"2025-01-01T00:00:00Z"}\n\n',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }

        throw StateError(
            'Unexpected request: ${request.method} ${request.url}');
      });
      final client = TbdAgentsClient(
        baseUrl: 'https://example.com',
        httpClient: mock,
      );

      expect(await client.knowledgeItems.list(), isEmpty);
      final filteredItems = await client.knowledgeItems.list(
        sourceId: 'ks_1',
        tags: const ['docs', 'api'],
        contentType: 'file',
      );
      expect(filteredItems.single.id, 'ki_1');
      expect((await client.knowledgeItems.get('ki_1')).sourceId, 'ks_1');
      expect(
        (await client.knowledgeItems.create({'name': 'hello.txt'})).name,
        'hello.txt',
      );
      expect(
        (await client.knowledgeItems.update('ki_1', {'name': 'new-name'})).id,
        'ki_1',
      );
      await client.knowledgeItems.delete('ki_1');
      expect(
        await client.knowledgeItems.query(tags: const ['docs'], limit: 3),
        {
          'tags': ['docs'],
          'limit': 3
        },
      );
      final download = await client.knowledgeItems.download('ki_1');
      expect(download.filename, 'notes.txt');
      expect(download.contentType, 'text/plain');
      expect(download.bytes, [1, 2, 3]);
      await expectLater(
        client.knowledgeItems.download('ki_2'),
        throwsA(isA<Exception>()),
      );

      expect((await client.tasks.list()).single.id, 'task_1');
      expect((await client.tasks.get('task_1')).status, 'running');
      expect(
        (await client.tasks
                .waitForCompletion('task_1', intervalMs: 0, timeoutMs: 50))
            .status,
        'completed',
      );
      await client.tasks.delete('task_1');

      expect((await client.workflows.list()).single.id, 'wf_1');
      expect((await client.workflows.get('wf_1')).id, 'wf_1');
      expect(
        (await client.workflows
                .create(const WorkflowCreate(agentId: 'agent_1')))
            .id,
        'wf_created',
      );
      expect(
        (await client.workflows.createRaw({'agent_id': 'agent_1'})).id,
        'wf_created',
      );
      expect(
        (await client.workflows
                .update('wf_1', const WorkflowUpdate(title: 'Updated')))
            .id,
        'wf_updated',
      );
      await client.workflows.delete('wf_1');
      expect(await client.workflows.export(), {'scope': 'all'});
      expect(await client.workflows.export(workflowId: 'wf_1'),
          {'scope': 'single'});
      expect(
          await client.workflows.import_({'id': 'wf_1'}), {'imported': true});
      expect(
        (await client.workflows.sendPrompt(
          'wf_1',
          request: {'prompt': 'hello'},
          reasoningEffort: 'high',
        ))
            .workflowId,
        'wf_1',
      );
      expect((await client.workflows.halt('wf_1')).detail, 'halted');
      expect((await client.workflows.installSkill('wf_1', 'skill_1')).id,
          'wf_installed');
      expect((await client.workflows.removeSkill('wf_1', 'skill_1')).id,
          'wf_removed');
      expect((await client.workflows.listTasks('wf_1')).single.id, 'task_2');
      expect(
        (await client.workflows.waitForStatus(
          'wf_1',
          (workflow) => workflow.lastTaskStatus == 'completed',
          intervalMs: 0,
          timeoutMs: 50,
        ))
            .lastTaskStatus,
        'completed',
      );
      expect(
        (await client.workflows
                .waitForCompletion('wf_1', intervalMs: 0, timeoutMs: 50))
            .lastTaskStatus,
        'completed',
      );
      final streamEvents = await client.workflows.stream('wf_stream').toList();
      expect(streamEvents, hasLength(1));
      expect(streamEvents.single.type, 'status');
      expect((streamEvents.single.data as Map<String, dynamic>)['state'],
          'running');

      client.close();
    });
  });

  group('exceptions', () {
    test('exception toString methods include useful context', () {
      expect(
        const TbdAgentsException('boom').toString(),
        'TbdAgentsException: boom',
      );
      expect(
        const TransportException('offline').toString(),
        'TransportException: offline',
      );
      expect(
        const TransportException('offline', cause: 'socket').toString(),
        'TransportException: offline (caused by socket)',
      );
      expect(
        const ApiException('bad', statusCode: 418).toString(),
        'ApiException(418): bad',
      );
    });
  });
}
