import 'package:test/test.dart';
import 'package:tbd_agents/tbd_agents.dart';

void main() {
  group('simple models', () {
    test(
        'serialize and deserialize health, usage, log, message, and import result',
        () {
      final health = HealthStatus.fromJson({'status': 'ok', 'region': 'us'});
      final usage = UsageStats.fromJson({
        'total_premium_requests': 2,
        'total_input_tokens': 10,
        'total_output_tokens': 5,
        'total_cache_read_tokens': 3,
        'total_cache_write_tokens': 1,
        'total_cost': 4,
      });
      final log = LogEntry.fromJson({
        'timestamp': '2025-01-01T00:00:00Z',
        'event': 'created',
        'detail': 'workflow created',
      });
      final message = Message.fromJson({
        'role': 'assistant',
        'content': 'hello',
        'tool_calls': [
          {'name': 'search'},
        ],
        'tool_call_id': 'tool_1',
        'name': 'planner',
      });
      final importResult = ImportResult.fromJson({
        'created': 3,
        'errors': ['bad row'],
        'ids': ['one', 'two'],
      });

      expect(health.status, 'ok');
      expect(health.extras['region'], 'us');
      expect(health.toJson(), {'status': 'ok'});

      expect(usage.totalPremiumRequests, 2.0);
      expect(usage.totalCost, 4.0);
      expect(usage.toJson()['total_output_tokens'], 5);

      expect(log.toJson(), {
        'timestamp': '2025-01-01T00:00:00Z',
        'event': 'created',
        'detail': 'workflow created',
      });

      expect(message.role, 'assistant');
      expect(message.toolCalls, [
        {'name': 'search'},
      ]);
      expect(message.toJson(), {
        'role': 'assistant',
        'content': 'hello',
        'tool_calls': [
          {'name': 'search'},
        ],
        'tool_call_id': 'tool_1',
        'name': 'planner',
      });

      expect(importResult.toJson(), {
        'created': 3,
        'errors': ['bad row'],
        'ids': ['one', 'two'],
      });
    });
  });

  group('workflow models', () {
    test('WorkflowCreate and WorkflowUpdate emit snake_case payloads', () {
      final create = WorkflowCreate(
        agentId: 'agent_1',
        title: 'Coverage run',
        maxTurns: 8,
        outputFormat: 'markdown',
        model: 'gpt-5',
        skillIds: const ['skill_1'],
        skillTags: const ['tag_1'],
        infiniteSession: false,
        caveman: true,
        bypassMemory: true,
        autoMemory: true,
        tsvToolResults: true,
        reasoningEffort: 'high',
        guardrailIds: const ['guard_1'],
        guardrailTags: const ['safe'],
        repoUrl: 'https://example.com/repo.git',
        repoBranch: 'main',
        repoTokenName: 'TOKEN',
        repositoryIds: const ['repo_1'],
        repositoryTags: const ['mobile'],
      );
      final update = WorkflowUpdate(
        title: 'Updated',
        agentId: 'agent_2',
        maxTurns: 4,
        outputFormat: 'json',
        model: 'gpt-4.1',
        skillIds: const ['skill_2'],
        skillTags: const ['tag_2'],
        infiniteSession: true,
        caveman: false,
        bypassMemory: false,
        autoMemory: true,
        tsvToolResults: false,
        reasoningEffort: 'medium',
        guardrailIds: const ['guard_2'],
        guardrailTags: const ['policy'],
        repoUrl: 'https://example.com/next.git',
        repoBranch: 'develop',
        repoTokenName: 'ALT_TOKEN',
        repositoryIds: const ['repo_2'],
        repositoryTags: const ['sdk'],
        status: 'paused',
      );

      expect(create.toJson(), {
        'agent_id': 'agent_1',
        'title': 'Coverage run',
        'max_turns': 8,
        'output_format': 'markdown',
        'model': 'gpt-5',
        'skill_ids': ['skill_1'],
        'skill_tags': ['tag_1'],
        'infinite_session': false,
        'caveman': true,
        'bypass_memory': true,
        'auto_memory': true,
        'tsv_tool_results': true,
        'reasoning_effort': 'high',
        'guardrail_ids': ['guard_1'],
        'guardrail_tags': ['safe'],
        'repo_url': 'https://example.com/repo.git',
        'repo_branch': 'main',
        'repo_token_name': 'TOKEN',
        'repository_ids': ['repo_1'],
        'repository_tags': ['mobile'],
      });
      expect(update.toJson(), {
        'title': 'Updated',
        'agent_id': 'agent_2',
        'max_turns': 4,
        'output_format': 'json',
        'model': 'gpt-4.1',
        'skill_ids': ['skill_2'],
        'skill_tags': ['tag_2'],
        'infinite_session': true,
        'caveman': false,
        'bypass_memory': false,
        'auto_memory': true,
        'tsv_tool_results': false,
        'reasoning_effort': 'medium',
        'guardrail_ids': ['guard_2'],
        'guardrail_tags': ['policy'],
        'repo_url': 'https://example.com/next.git',
        'repo_branch': 'develop',
        'repo_token_name': 'ALT_TOKEN',
        'repository_ids': ['repo_2'],
        'repository_tags': ['sdk'],
        'status': 'paused',
      });
    });

    test('Workflow parses nested collections and fallback defaults', () {
      final json = {
        'id': 'wf_1',
        'title': 'Example',
        'agent_id': 'agent_1',
        'github_user': 'octocat',
        'model': 'gpt-5',
        'max_turns': 5,
        'current_turn': 2,
        'session_id': 'sess_1',
        'skill_ids': ['skill_1'],
        'skill_tags': ['tag_1'],
        'status': 'running',
        'output_format': 'json',
        'infinite_session': false,
        'caveman': true,
        'bypass_memory': true,
        'auto_memory': true,
        'tsv_tool_results': true,
        'reasoning_effort': 'high',
        'guardrail_ids': ['guard_1'],
        'guardrail_tags': ['tag_2'],
        'repo_url': 'https://example.com/repo.git',
        'repo_branch': 'main',
        'repo_token_name': 'TOKEN',
        'repository_ids': ['repo_1'],
        'repository_tags': ['sdk'],
        'usage': {
          'total_premium_requests': 1,
          'total_input_tokens': 11,
          'total_output_tokens': 7,
          'total_cache_read_tokens': 2,
          'total_cache_write_tokens': 3,
          'total_cost': 9.5,
        },
        'logs': [
          {
            'timestamp': '2025-01-01T00:00:00Z',
            'event': 'started',
            'detail': 'ready',
          },
        ],
        'messages': [
          {
            'role': 'assistant',
            'content': 'done',
          },
        ],
        'task_count': 4,
        'last_task_status': 'completed',
        'last_task_at': '2025-01-01T00:00:01Z',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:01Z',
        'extra_flag': true,
      };

      final workflow = Workflow.fromJson(json);
      final fallback = Workflow.fromJson({
        'id': 'wf_2',
        'agent_id': 'agent_2',
        'github_user': 'user',
        'model': 'gpt',
        'max_turns': 0,
        'current_turn': 0,
        'status': 'queued',
        'output_format': 'json',
        'skill_ids': ['ignored', 1],
        'infinite_session': 'not-bool',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
      });

      expect(workflow.title, 'Example');
      expect(workflow.skillTags, ['tag_1']);
      expect(workflow.infiniteSession, isFalse);
      expect(workflow.usage?.totalCost, 9.5);
      expect(workflow.logs.single.event, 'started');
      expect(workflow.messages.single.content, 'done');
      expect(workflow.lastTaskStatus, 'completed');
      expect(workflow.extras['extra_flag'], isTrue);

      expect(fallback.skillIds, ['ignored']);
      expect(fallback.infiniteSession, isTrue);
      expect(fallback.logs, isEmpty);
      expect(fallback.messages, isEmpty);
      expect(fallback.usage, isNull);
    });
  });

  group('prompt and task models', () {
    test(
        'PromptRequest requires prompt or request and serializes optional fields',
        () {
      expect(() => PromptRequest(), throwsA(isA<AssertionError>()));

      final request = PromptRequest(
        prompt: 'hello',
        request: {'mode': 'json'},
        reasoningEffort: 'low',
      );

      expect(request.toJson(), {
        'prompt': 'hello',
        'request': {'mode': 'json'},
        'reasoning_effort': 'low',
      });
    });

    test(
        'PromptResponse, stream events, todos, progress, and tasks parse nested data',
        () {
      final response = PromptResponse.fromJson({
        'workflow_id': 'wf_1',
        'status': 'running',
        'current_turn': 3,
        'max_turns': 9,
        'response': 'partial',
        'output_format': 'markdown',
        'infinite_session': false,
        'caveman': true,
        'tsv_tool_results': true,
        'usage': {
          'total_input_tokens': 3,
          'total_output_tokens': 4,
        },
        'logs': [
          {
            'timestamp': '2025-01-01T00:00:00Z',
            'event': 'tick',
            'detail': 'progress',
          },
        ],
        'messages': [
          {
            'role': 'assistant',
            'content': 'partial',
          },
        ],
        'server': 'api-1',
      });
      final event = WorkflowStreamEvent.fromJson({
        'id': 8,
        'type': 'status',
        'data': {'status': 'running'},
        'timestamp': '2025-01-01T00:00:00Z',
      });
      final todo = TodoItem.fromJson({
        'id': 5,
        'title': 'Write tests',
        'status': 'done',
      });
      final progress = TaskProgress.fromJson({
        'todos': [
          {
            'id': 'todo_1',
            'title': 'Inspect package',
            'status': 'done',
          },
        ],
        'current_step': 'verifying',
        'percent_complete': 87,
      });
      final task = TaskExecution.fromJson({
        'id': 'task_1',
        'workflow_id': 'wf_1',
        'workflow_title': 'Coverage',
        'agent_name': 'tester',
        'prompt': 'run coverage',
        'status': 'completed',
        'celery_task_id': 'celery_1',
        'worker': 'worker-1',
        'model': 'gpt-5',
        'reasoning_effort': 'medium',
        'tool_calls': 2,
        'response': 'done',
        'progress': {
          'todos': [
            {
              'id': 'todo_2',
              'title': 'Verify result',
              'status': 'done',
            },
          ],
          'current_step': 'complete',
          'percent_complete': 100,
        },
        'logs': [
          {
            'timestamp': '2025-01-01T00:00:00Z',
            'event': 'done',
            'detail': 'ok',
          },
        ],
        'messages': [
          {
            'role': 'assistant',
            'content': 'complete',
          },
        ],
        'usage': {
          'total_cost': 1.5,
        },
        'started_at': '2025-01-01T00:00:00Z',
        'finished_at': '2025-01-01T00:00:01Z',
        'elapsed_seconds': 1,
        'created_at': '2025-01-01T00:00:00Z',
        'trace_id': 'trace_1',
      });

      expect(response.outputFormat, 'markdown');
      expect(response.infiniteSession, isFalse);
      expect(response.logs.single.detail, 'progress');
      expect(response.messages.single.content, 'partial');
      expect(response.extras['server'], 'api-1');

      expect(event.id, 8);
      expect(event.toString(), 'WorkflowStreamEvent(id: 8, type: status)');

      expect(todo.id, 5);
      expect(progress.todos.single.title, 'Inspect package');
      expect(progress.percentComplete, 87.0);

      expect(task.workflowTitle, 'Coverage');
      expect(task.progress?.todos.single.status, 'done');
      expect(task.usage?.totalCost, 1.5);
      expect(task.elapsedSeconds, 1.0);
      expect(task.extras['trace_id'], 'trace_1');
    });
  });

  group('knowledge and detail models', () {
    test('KnowledgeItem preserves metadata and DetailResponse keeps extras',
        () {
      final item = KnowledgeItem.fromJson({
        'id': 'ki_1',
        'source_id': 'ks_1',
        'name': 'hello.txt',
        'content_type': 'file',
        'text_content': 'hello',
        'file_id': 'file_1',
        'file_name': 'hello.txt',
        'file_size': 128,
        'mime_type': 'text/plain',
        'tags': ['docs', 1],
        'metadata': {'team': 'mobile'},
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:01Z',
        'custom': true,
      });
      const downloaded = DownloadedContent(
        bytes: [1, 2, 3],
        contentType: 'text/plain',
        filename: 'hello.txt',
      );
      final detail = DetailResponse.fromJson({
        'detail': 'halted',
        'status': 'ok',
      });

      expect(item.tags, ['docs']);
      expect(item.metadata, {'team': 'mobile'});
      expect(item.extras['custom'], isTrue);

      expect(downloaded.bytes, [1, 2, 3]);
      expect(downloaded.contentType, 'text/plain');
      expect(downloaded.filename, 'hello.txt');

      expect(detail.detail, 'halted');
      expect(detail.extras['status'], 'ok');
    });
  });
}
