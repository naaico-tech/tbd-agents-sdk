/// Tasks resource — `/api/tasks`.
library;

import '../models.dart';
import 'base.dart';

/// Terminal task statuses used by [TasksResource.waitForCompletion].
const _terminalStatuses = {
  'completed',
  'failed',
  'halted',
  'max_turns_reached',
};

class TasksResource extends BaseResource {
  const TasksResource(super.client);

  /// `GET /api/tasks` — list all tasks.
  Future<List<TaskExecution>> list() async {
    final data = await client.request('GET', 'tasks');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(TaskExecution.fromJson).toList();
    }
    return const [];
  }

  /// `GET /api/tasks/{id}` — fetch a single task.
  Future<TaskExecution> get(String id) async {
    final data = await client.request('GET', 'tasks/$id');
    return TaskExecution.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  /// `DELETE /api/tasks/{id}` — cancel / delete a task.
  Future<void> delete(String id) => client.request('DELETE', 'tasks/$id');

  /// Polls [get] until the task reaches a terminal status or [timeoutMs]
  /// elapses.
  Future<TaskExecution> waitForCompletion(
    String id, {
    int intervalMs = 1000,
    int timeoutMs = 300000,
  }) {
    return pollUntil(
      () => get(id),
      predicate: (task) => _terminalStatuses.contains(task.status),
      intervalMs: intervalMs,
      timeoutMs: timeoutMs,
    );
  }
}
