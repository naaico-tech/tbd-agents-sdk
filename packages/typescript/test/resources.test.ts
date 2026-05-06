import { describe, expect, it, vi } from 'vitest';
import type { TbdAgentsClient } from '../src/client.js';
import { CollectionResource } from '../src/resources/generic.js';
import { HealthResource } from '../src/resources/health.js';
import { KnowledgeItemsResource } from '../src/resources/knowledge-items.js';
import { KnowledgeSourcesResource } from '../src/resources/knowledge-sources.js';
import { TasksResource } from '../src/resources/tasks.js';
import { WorkflowsResource } from '../src/resources/workflows.js';
import { pollUntil } from '../src/resources/base.js';

function createStubClient() {
  return {
    request: vi.fn(),
    raw: vi.fn(),
  } as unknown as TbdAgentsClient & {
    request: ReturnType<typeof vi.fn>;
    raw: ReturnType<typeof vi.fn>;
  };
}

function createSseResponse(chunks: string[]): Response {
  return new Response(
    new ReadableStream<Uint8Array>({
      start(controller) {
        for (const chunk of chunks) {
          controller.enqueue(new TextEncoder().encode(chunk));
        }
        controller.close();
      },
    }),
    {
      headers: {
        'content-type': 'text/event-stream',
      },
    },
  );
}

describe('resource helpers', () => {
  it('pollUntil resolves when the predicate passes', async () => {
    const value = await pollUntil(
      vi
        .fn<() => Promise<{ status: string }>>()
        .mockResolvedValueOnce({ status: 'pending' })
        .mockResolvedValueOnce({ status: 'done' }),
      {
        intervalMs: 0,
        timeoutMs: 100,
        predicate: (result) => result.status === 'done',
      },
    );

    expect(value).toEqual({ status: 'done' });
  });

  it('pollUntil times out when the predicate never passes', async () => {
    vi.useFakeTimers();

    const promise = pollUntil(
      vi.fn<() => Promise<{ status: string }>>().mockResolvedValue({ status: 'pending' }),
      {
        intervalMs: 10,
        timeoutMs: 20,
        predicate: (result) => result.status === 'done',
      },
    );

    // Attach the rejection handler before advancing timers to prevent unhandled rejections
    const assertion = expect(promise).rejects.toThrow('Polling timed out after 20ms');
    await vi.advanceTimersByTimeAsync(30);
    await assertion;

    vi.useRealTimers();
  });

  it('pollUntil rejects when the signal aborts during the delay', async () => {
    const controller = new AbortController();
    const promise = pollUntil(
      vi.fn<() => Promise<{ status: string }>>().mockResolvedValue({ status: 'pending' }),
      {
        intervalMs: 1_000,
        timeoutMs: 2_000,
        signal: controller.signal,
        predicate: (result) => result.status === 'done',
      },
    );

    controller.abort(new Error('stop polling'));

    await expect(promise).rejects.toThrow('stop polling');
  });
});

describe('CollectionResource', () => {
  it('maps CRUD operations to request calls', async () => {
    const client = createStubClient();
    const resource = new CollectionResource<{ id: string; name: string }>(client, 'widgets');

    await resource.list();
    await resource.list({ page: 2 });
    await resource.get('widget/id');
    await resource.create({ name: 'new widget' });
    await resource.update('widget/id', { name: 'updated widget' });
    await resource.delete('widget/id');

    expect(client.request).toHaveBeenNthCalledWith(1, { path: 'widgets' });
    expect(client.request).toHaveBeenNthCalledWith(2, { path: 'widgets', query: { page: 2 } });
    expect(client.request).toHaveBeenNthCalledWith(3, { path: 'widgets/widget%2Fid' });
    expect(client.request).toHaveBeenNthCalledWith(4, {
      path: 'widgets',
      method: 'POST',
      body: { name: 'new widget' },
    });
    expect(client.request).toHaveBeenNthCalledWith(5, {
      path: 'widgets/widget%2Fid',
      method: 'PUT',
      body: { name: 'updated widget' },
    });
    expect(client.request).toHaveBeenNthCalledWith(6, {
      path: 'widgets/widget%2Fid',
      method: 'DELETE',
      responseType: 'void',
    });
  });
});

describe('resource endpoints', () => {
  it('requests the health endpoint outside the API prefix', async () => {
    const client = createStubClient();

    await new HealthResource(client).check();

    expect(client.request).toHaveBeenCalledWith({
      path: '/health',
      api: false,
    });
  });

  it('uploads and downloads knowledge items', async () => {
    const client = createStubClient();
    const resource = new KnowledgeItemsResource(client);
    const response = new Response(Uint8Array.from([1, 2, 3]).buffer, {
      headers: {
        'content-type': 'text/plain',
        'content-disposition': `attachment; filename*=UTF-8''guide.txt`,
      },
    });
    client.raw.mockResolvedValue(response);

    await resource.createText({
      source_id: 'source-1',
      name: 'Readme',
      text_content: 'hello',
    });
    await resource.query({ limit: 5, tags: ['docs'] });
    await resource.upload({
      sourceId: 'source-1',
      file: new ArrayBuffer(3),
      contentType: 'text/plain',
    });

    const downloaded = await resource.downloadContent('item/id');

    expect(client.request).toHaveBeenNthCalledWith(1, {
      path: 'knowledge-items',
      method: 'POST',
      body: {
        source_id: 'source-1',
        name: 'Readme',
        text_content: 'hello',
      },
    });
    expect(client.request).toHaveBeenNthCalledWith(2, {
      path: 'knowledge-items/query',
      method: 'POST',
      body: { limit: 5, tags: ['docs'] },
    });

    const uploadCall = client.request.mock.calls[2]?.[0];
    expect(uploadCall.path).toBe('knowledge-items/upload');
    expect(uploadCall.method).toBe('POST');
    expect(uploadCall.body).toBeInstanceOf(FormData);
    expect((uploadCall.body as FormData).get('file')).toBeInstanceOf(File);
    expect((uploadCall.body as FormData).get('source_id')).toBe('source-1');
    expect((uploadCall.body as FormData).get('tags')).toBeNull();
    expect((uploadCall.body as FormData).get('metadata')).toBeNull();

    expect(client.raw).toHaveBeenCalledWith({
      path: 'knowledge-items/item%2Fid/content',
    });
    expect(downloaded).toMatchObject({
      data: Uint8Array.from([1, 2, 3]),
      contentType: 'text/plain',
      fileName: 'guide.txt',
      response,
    });
  });

  it('tests knowledge sources and task endpoints', async () => {
    const client = createStubClient();
    const knowledgeSources = new KnowledgeSourcesResource(client);
    const tasks = new TasksResource(client);
    client.request
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce({ id: 'task-1', status: 'queued', workflow_id: 'wf-1' })
      .mockResolvedValueOnce({ id: 'task-1', percent_complete: 10 })
      .mockResolvedValueOnce({ id: 'task-1', status: 'running', workflow_id: 'wf-1' })
      .mockResolvedValueOnce({ id: 'task-1', status: 'completed', workflow_id: 'wf-1' })
      .mockResolvedValueOnce({ id: 'task-1', status: 'completed', workflow_id: 'wf-1' });

    await knowledgeSources.test('source/id');
    await tasks.list();
    await tasks.list({ status: 'running' });
    await tasks.listForWorkflow('workflow/id');
    await tasks.get('task/id');
    await tasks.progress('task/id');
    const completed = await tasks.waitForCompletion('task-1', {
      intervalMs: 0,
      timeoutMs: 100,
    });

    expect(client.request).toHaveBeenNthCalledWith(1, {
      path: 'knowledge-sources/source%2Fid/test',
      method: 'POST',
    });
    expect(client.request).toHaveBeenNthCalledWith(2, { path: 'tasks' });
    expect(client.request).toHaveBeenNthCalledWith(3, { path: 'tasks', query: { status: 'running' } });
    expect(client.request).toHaveBeenNthCalledWith(4, { path: 'tasks/workflow/workflow%2Fid' });
    expect(client.request).toHaveBeenNthCalledWith(5, { path: 'tasks/task%2Fid' });
    expect(client.request).toHaveBeenNthCalledWith(6, { path: 'tasks/task%2Fid/progress' });
    expect(completed.status).toBe('completed');
  });

  it('maps workflow endpoints, streaming, and terminal polling', async () => {
    const client = createStubClient();
    const workflows = new WorkflowsResource(client);
    const signal = new AbortController().signal;
    client.raw.mockResolvedValue(
      createSseResponse([
        'data: {"id":"evt_1","type":"status","data":{"status":"running"},"timestamp":"2026-01-01T00:00:00Z"}\n\n',
      ]),
    );
    client.request
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce({ id: 'wf-1', status: 'active' })
      .mockResolvedValueOnce({ id: 'wf-1', status: 'active' })
      .mockResolvedValueOnce(undefined)
      .mockResolvedValueOnce({ workflow_id: 'wf-1', status: 'active', current_turn: 1, max_turns: 5, output_format: 'markdown', logs: [], messages: [] })
      .mockResolvedValueOnce({ detail: 'halted' })
      .mockResolvedValueOnce({ id: 'wf-1', status: 'active' })
      .mockResolvedValueOnce({ id: 'wf-1', status: 'active' })
      .mockResolvedValueOnce({ id: 'wf-1', status: 'active', last_task_status: 'running' })
      .mockResolvedValueOnce({ id: 'wf-1', status: 'inactive' })
      .mockResolvedValueOnce({ id: 'wf-1', status: 'active', last_task_status: 'completed' });

    await workflows.list();
    await workflows.get('workflow/id');
    await workflows.create({ agent_id: 'agent-1' });
    await workflows.delete('workflow/id');
    await workflows.sendPrompt('workflow/id', { prompt: 'hello' });
    await workflows.halt('workflow/id');
    await workflows.installSkill('workflow/id', 'skill/id');
    await workflows.removeSkill('workflow/id', 'skill/id');
    const events = [];
    for await (const event of workflows.stream('workflow/id', { signal })) {
      events.push(event);
    }
    const inactive = await workflows.waitForStatus('wf-1', ['inactive'], {
      intervalMs: 0,
      timeoutMs: 100,
    });
    const finished = await workflows.waitForCompletion('wf-1', {
      intervalMs: 0,
      timeoutMs: 100,
    });

    expect(client.request).toHaveBeenNthCalledWith(1, { path: 'workflows' });
    expect(client.request).toHaveBeenNthCalledWith(2, { path: 'workflows/workflow%2Fid' });
    expect(client.request).toHaveBeenNthCalledWith(3, {
      path: 'workflows',
      method: 'POST',
      body: { agent_id: 'agent-1' },
    });
    expect(client.request).toHaveBeenNthCalledWith(4, {
      path: 'workflows/workflow%2Fid',
      method: 'DELETE',
      responseType: 'void',
    });
    expect(client.request).toHaveBeenNthCalledWith(5, {
      path: 'workflows/workflow%2Fid/prompt',
      method: 'POST',
      body: { prompt: 'hello' },
    });
    expect(client.request).toHaveBeenNthCalledWith(6, {
      path: 'workflows/workflow%2Fid/halt',
      method: 'POST',
    });
    expect(client.request).toHaveBeenNthCalledWith(7, {
      path: 'workflows/workflow%2Fid/skills/skill%2Fid',
      method: 'POST',
    });
    expect(client.request).toHaveBeenNthCalledWith(8, {
      path: 'workflows/workflow%2Fid/skills/skill%2Fid',
      method: 'DELETE',
    });
    expect(client.raw).toHaveBeenCalledWith({
      path: 'workflows/workflow%2Fid/stream',
      headers: {
        accept: 'text/event-stream',
      },
      signal,
    });
    expect(events).toEqual([{ id: 'evt_1', type: 'status', data: { status: 'running' }, timestamp: '2026-01-01T00:00:00Z' }]);
    expect(inactive.status).toBe('inactive');
    expect(finished.last_task_status).toBe('completed');
  });
});
