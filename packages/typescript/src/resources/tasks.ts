import { BaseResource, pollUntil } from './base.js';
import type {
  QueryParams,
  TaskExecution,
  TaskProgress,
  TaskSummary,
} from '../types.js';

export interface TaskPollOptions {
  intervalMs?: number;
  timeoutMs?: number;
  signal?: AbortSignal;
}

export class TasksResource extends BaseResource {
  list(query?: QueryParams): Promise<TaskSummary[]> {
    return this.client.request<TaskSummary[]>(
      query
        ? {
            path: 'tasks',
            query,
          }
        : {
            path: 'tasks',
          },
    );
  }

  listForWorkflow(workflowId: string): Promise<TaskSummary[]> {
    return this.client.request<TaskSummary[]>({
      path: `tasks/workflow/${encodeURIComponent(workflowId)}`,
    });
  }

  get(id: string): Promise<TaskExecution> {
    return this.client.request<TaskExecution>({
      path: `tasks/${encodeURIComponent(id)}`,
    });
  }

  progress(id: string): Promise<TaskProgress> {
    return this.client.request<TaskProgress>({
      path: `tasks/${encodeURIComponent(id)}/progress`,
    });
  }

  waitForStatus(
    id: string,
    statuses: string[],
    options?: TaskPollOptions,
  ): Promise<TaskExecution> {
    return pollUntil(() => this.get(id), {
      ...options,
      predicate: (task) => statuses.includes(task.status),
    });
  }

  waitForCompletion(id: string, options?: TaskPollOptions): Promise<TaskExecution> {
    return this.waitForStatus(id, ['completed', 'failed', 'cancelled'], options);
  }
}
