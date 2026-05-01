import { BaseResource, pollUntil } from './base.js';
import { parseSseStream } from '../sse.js';
import type {
  PromptResponse,
  Workflow,
  WorkflowCreateInput,
  WorkflowPromptInput,
  WorkflowStreamEvent,
  WorkflowUpdateInput,
} from '../types.js';

export interface WorkflowPollOptions {
  intervalMs?: number;
  timeoutMs?: number;
  signal?: AbortSignal;
}

const TERMINAL_TASK_STATUSES = ['completed', 'failed', 'halted', 'max_turns_reached'];

export class WorkflowsResource extends BaseResource {
  list(): Promise<Workflow[]> {
    return this.client.request<Workflow[]>({
      path: 'workflows',
    });
  }

  get(id: string): Promise<Workflow> {
    return this.client.request<Workflow>({
      path: `workflows/${encodeURIComponent(id)}`,
    });
  }

  create(body: WorkflowCreateInput): Promise<Workflow> {
    return this.client.request<Workflow, WorkflowCreateInput>({
      path: 'workflows',
      method: 'POST',
      body,
    });
  }

  update(id: string, body: WorkflowUpdateInput): Promise<Workflow> {
    return this.client.request<Workflow, WorkflowUpdateInput>({
      path: `workflows/${encodeURIComponent(id)}`,
      method: 'PUT',
      body,
    });
  }

  delete(id: string): Promise<void> {
    return this.client.request<void>({
      path: `workflows/${encodeURIComponent(id)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }

  sendPrompt(id: string, body: WorkflowPromptInput): Promise<PromptResponse> {
    return this.client.request<PromptResponse, WorkflowPromptInput>({
      path: `workflows/${encodeURIComponent(id)}/prompt`,
      method: 'POST',
      body,
    });
  }

  halt(id: string): Promise<{ detail: string }> {
    return this.client.request<{ detail: string }>({
      path: `workflows/${encodeURIComponent(id)}/halt`,
      method: 'POST',
    });
  }

  installSkill(workflowId: string, skillId: string): Promise<Workflow> {
    return this.client.request<Workflow>({
      path: `workflows/${encodeURIComponent(workflowId)}/skills/${encodeURIComponent(skillId)}`,
      method: 'POST',
    });
  }

  removeSkill(workflowId: string, skillId: string): Promise<Workflow> {
    return this.client.request<Workflow>({
      path: `workflows/${encodeURIComponent(workflowId)}/skills/${encodeURIComponent(skillId)}`,
      method: 'DELETE',
    });
  }

  async *stream(
    id: string,
    options?: { signal?: AbortSignal },
  ): AsyncGenerator<WorkflowStreamEvent, void, void> {
    const response = await this.client.raw(
      options?.signal
        ? {
            path: `workflows/${encodeURIComponent(id)}/stream`,
            headers: {
              accept: 'text/event-stream',
            },
            signal: options.signal,
          }
        : {
            path: `workflows/${encodeURIComponent(id)}/stream`,
            headers: {
              accept: 'text/event-stream',
            },
          },
    );

    for await (const message of parseSseStream<WorkflowStreamEvent>(response, {
      parser: (value) => JSON.parse(value) as WorkflowStreamEvent,
    })) {
      yield message.data;
    }
  }

  waitForStatus(
    id: string,
    statuses: string[],
    options?: WorkflowPollOptions,
  ): Promise<Workflow> {
    return pollUntil(() => this.get(id), {
      ...options,
      predicate: (workflow) => statuses.includes(workflow.status),
    });
  }

  waitForCompletion(id: string, options?: WorkflowPollOptions): Promise<Workflow> {
    return pollUntil(() => this.get(id), {
      ...options,
      predicate: (workflow) =>
        typeof workflow.last_task_status === 'string'
        && TERMINAL_TASK_STATUSES.includes(workflow.last_task_status),
    });
  }
}
