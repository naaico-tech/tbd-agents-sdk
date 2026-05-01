import { describe, expect, it, vi } from 'vitest';
import { TbdAgentsClient } from '../src/client.js';

describe('TbdAgentsClient', () => {
  it('builds API requests with bearer auth and JSON bodies', async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, init?: RequestInit) => {
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: {
          'content-type': 'application/json',
        },
      });
    });

    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com/',
      token: 'secret-token',
      fetch: fetchMock,
      headers: {
        'x-sdk': 'typescript',
      },
    });

    await client.workflows.sendPrompt('wf_123', {
      prompt: 'hello',
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);

    const [input, init] = fetchMock.mock.calls[0] ?? [];
    expect(String(input)).toBe('https://example.com/api/workflows/wf_123/prompt');

    const headers = new Headers(init?.headers);
    expect(init?.method).toBe('POST');
    expect(headers.get('authorization')).toBe('Bearer secret-token');
    expect(headers.get('content-type')).toBe('application/json');
    expect(headers.get('x-sdk')).toBe('typescript');
    expect(init?.body).toBe(JSON.stringify({ prompt: 'hello' }));
  });

  it('routes health checks outside the /api base', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      return new Response(JSON.stringify({ status: 'ok' }), {
        status: 200,
        headers: {
          'content-type': 'application/json',
        },
      });
    });

    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com/platform',
      token: 'token',
      fetch: fetchMock,
    });

    await client.health.check();

    const [input] = fetchMock.mock.calls[0] ?? [];
    expect(String(input)).toBe('https://example.com/health');
  });

  it('sends multipart uploads for knowledge item files', async () => {
    const fetchMock = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => {
      return new Response(JSON.stringify({ id: 'ki_1', source_id: 'ks_1' }), {
        status: 200,
        headers: {
          'content-type': 'application/json',
        },
      });
    });

    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      token: 'token',
      fetch: fetchMock,
    });

    await client.knowledgeItems.upload({
      sourceId: 'ks_1',
      file: new Uint8Array([1, 2, 3]),
      fileName: 'hello.txt',
      tags: ['docs', 'ops'],
      metadata: { team: 'platform' },
    });

    const [, init] = fetchMock.mock.calls[0] ?? [];
    expect(init?.method).toBe('POST');
    expect(init?.body).toBeInstanceOf(FormData);

    const body = init?.body as FormData;
    expect(body.get('source_id')).toBe('ks_1');
    expect(body.get('tags')).toBe('["docs","ops"]');
    expect(body.get('metadata')).toBe('{"team":"platform"}');
  });

  it('waits for workflow run completion using last task status', async () => {
    const fetchMock = vi
      .fn<(_input: RequestInfo | URL, _init?: RequestInit) => Promise<Response>>()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            id: 'wf_123',
            agent_id: 'agent_1',
            model: 'gpt-4.1',
            max_turns: 10,
            current_turn: 0,
            skill_ids: [],
            status: 'active',
            output_format: 'markdown',
            logs: [],
            messages: [],
            last_task_status: 'running',
          }),
          {
            status: 200,
            headers: {
              'content-type': 'application/json',
            },
          },
        ),
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            id: 'wf_123',
            agent_id: 'agent_1',
            model: 'gpt-4.1',
            max_turns: 10,
            current_turn: 1,
            skill_ids: [],
            status: 'active',
            output_format: 'markdown',
            logs: [],
            messages: [],
            last_task_status: 'completed',
          }),
          {
            status: 200,
            headers: {
              'content-type': 'application/json',
            },
          },
        ),
      );

    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      token: 'token',
      fetch: fetchMock,
    });

    const workflow = await client.workflows.waitForCompletion('wf_123', {
      intervalMs: 0,
      timeoutMs: 100,
    });

    expect(workflow.last_task_status).toBe('completed');
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });
});
