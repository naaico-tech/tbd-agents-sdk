/// Workflows resource — `/api/workflows`.
library;

import 'dart:async';
import 'dart:convert';

import '../models.dart';
import '../sse.dart';
import 'base.dart';

/// Terminal task statuses used by [WorkflowsResource.waitForCompletion].
const _terminalTaskStatuses = {
  'completed',
  'failed',
  'halted',
  'max_turns_reached',
};

class WorkflowsResource extends BaseResource {
  const WorkflowsResource(super.client);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<List<Workflow>> list() async {
    final data = await client.request('GET', 'workflows');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Workflow.fromJson).toList();
    }
    return const [];
  }

  Future<Workflow> get(String id) async {
    final data = await client.request('GET', 'workflows/$id');
    return Workflow.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<Workflow> create(WorkflowCreate payload) async {
    final data =
        await client.request('POST', 'workflows', body: payload.toJson());
    return Workflow.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<Workflow> createRaw(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'workflows', body: payload);
    return Workflow.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<Workflow> update(String id, WorkflowUpdate payload) async {
    final data =
        await client.request('PUT', 'workflows/$id', body: payload.toJson());
    return Workflow.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<void> delete(String id) =>
      client.request('DELETE', 'workflows/$id');

  // ---------------------------------------------------------------------------
  // Import / export
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> export({String? workflowId}) async {
    final path = workflowId == null
        ? 'workflows/export'
        : 'workflows/$workflowId/export';
    final data = await client.request('GET', path);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> import_(Map<String, dynamic> payload) async {
    final data =
        await client.request('POST', 'workflows/import', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  // ---------------------------------------------------------------------------
  // Prompt + halt
  // ---------------------------------------------------------------------------

  /// `POST /api/workflows/{id}/prompt`
  Future<PromptResponse> sendPrompt(
    String id, {
    String? prompt,
    Map<String, dynamic>? request,
    String? reasoningEffort,
  }) async {
    final body = PromptRequest(
      prompt: prompt,
      request: request,
      reasoningEffort: reasoningEffort,
    );
    final data = await client.request(
      'POST',
      'workflows/$id/prompt',
      body: body.toJson(),
    );
    return PromptResponse.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  /// `POST /api/workflows/{id}/halt`
  Future<DetailResponse> halt(String id) async {
    final data = await client.request('POST', 'workflows/$id/halt');
    return DetailResponse.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  // ---------------------------------------------------------------------------
  // Skills
  // ---------------------------------------------------------------------------

  Future<Workflow> installSkill(String workflowId, String skillId) async {
    final data = await client.request(
      'POST',
      'workflows/$workflowId/skills/$skillId',
    );
    return Workflow.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<Workflow> removeSkill(String workflowId, String skillId) async {
    final data = await client.request(
      'DELETE',
      'workflows/$workflowId/skills/$skillId',
    );
    return Workflow.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  // ---------------------------------------------------------------------------
  // Tasks
  // ---------------------------------------------------------------------------

  /// `GET /api/tasks/workflow/{workflowId}`
  Future<List<TaskExecution>> listTasks(String workflowId) async {
    final data =
        await client.request('GET', 'tasks/workflow/$workflowId');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TaskExecution.fromJson)
          .toList();
    }
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Polling helpers
  // ---------------------------------------------------------------------------

  /// Polls [get] until [predicate] returns `true` or [timeoutMs] elapses.
  Future<Workflow> waitForStatus(
    String id,
    bool Function(Workflow) predicate, {
    int intervalMs = 1000,
    int timeoutMs = 300000,
  }) {
    return pollUntil(
      () => get(id),
      predicate: predicate,
      intervalMs: intervalMs,
      timeoutMs: timeoutMs,
    );
  }

  /// Polls until [Workflow.lastTaskStatus] is a terminal status.
  Future<Workflow> waitForCompletion(
    String id, {
    int intervalMs = 1000,
    int timeoutMs = 300000,
  }) {
    return waitForStatus(
      id,
      (w) =>
          w.lastTaskStatus != null &&
          _terminalTaskStatuses.contains(w.lastTaskStatus),
      intervalMs: intervalMs,
      timeoutMs: timeoutMs,
    );
  }

  // ---------------------------------------------------------------------------
  // SSE streaming
  // ---------------------------------------------------------------------------

  /// Opens an SSE stream at `GET /api/workflows/{id}/stream` and yields
  /// [WorkflowStreamEvent] objects.
  ///
  /// Pass [lastEventId] to resume from a known event position (the value is
  /// sent as the `Last-Event-ID` header).
  ///
  /// ```dart
  /// await for (final event in client.workflows.stream('wf_123')) {
  ///   print('${event.type}: ${event.data}');
  /// }
  /// ```
  Stream<WorkflowStreamEvent> stream(
    String id, {
    Object? lastEventId,
  }) async* {
    final headers = <String, String>{
      if (lastEventId != null) 'last-event-id': lastEventId.toString(),
    };

    final streamed = await client.streamRequest(
      'GET',
      'workflows/$id/stream',
      headers: headers,
    );

    await for (final message in parseSseStream(streamed.stream)) {
      if (message.data.isEmpty) continue;
      try {
        final decoded = json.decode(message.data);
        if (decoded is Map<String, dynamic>) {
          yield WorkflowStreamEvent.fromJson(decoded);
        }
      } catch (_) {
        // Skip malformed JSON frames.
      }
    }
  }
}
