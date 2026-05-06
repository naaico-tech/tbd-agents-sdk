import { describe, expect, it, vi } from 'vitest';
import * as sdk from '../src/index.js';
import { ApiError } from '../src/errors.js';
import { TbdAgentsClient } from '../src/client.js';

describe('package exports', () => {
  it('re-exports the public runtime API', () => {
    expect(sdk.TbdAgentsClient).toBe(TbdAgentsClient);
    expect(sdk.ApiError).toBe(ApiError);
    expect(typeof sdk.parseSseStream).toBe('function');
  });
});

describe('TbdAgentsClient request handling', () => {
  it('validates required constructor inputs', () => {
    expect(() => new TbdAgentsClient({ baseUrl: '' })).toThrow('baseUrl is required');
  });

  it('throws when no fetch implementation exists in the runtime', async () => {
    const originalFetch = globalThis.fetch;
    // @ts-expect-error intentionally removing fetch for runtime validation
    delete globalThis.fetch;

    try {
      expect(() => new TbdAgentsClient({ baseUrl: 'https://example.com' })).toThrow(
        'A fetch implementation is required in this runtime',
      );
    } finally {
      globalThis.fetch = originalFetch;
    }
  });

  it('appends query params, honors absolute URLs, and preserves explicit accept headers', async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: {
          'content-type': 'application/json',
        },
      });
    });
    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com/platform/',
      fetch: fetchMock,
      headers: {
        accept: 'application/vnd.custom+json',
      },
    });

    await client.request({
      path: 'https://uploads.example.com/files',
      query: {
        page: 2,
        flags: ['a', 'b'],
        since: new Date('2024-01-01T00:00:00.000Z'),
        skip: undefined,
        omit: null,
      },
    });

    const [input, init] = fetchMock.mock.calls[0] ?? [];
    expect(String(input)).toBe(
      'https://uploads.example.com/files?page=2&flags=a&flags=b&since=2024-01-01T00%3A00%3A00.000Z',
    );
    expect(init?.method).toBe('GET');
    expect(new Headers(init?.headers).get('accept')).toBe('application/vnd.custom+json');
  });

  it('supports text, json, blob, raw, void, and auto fallback responses', async () => {
    const fetchMock = vi
      .fn<(_input: RequestInfo | URL, _init?: RequestInit) => Promise<Response>>()
      .mockResolvedValueOnce(new Response('plain text', { headers: { 'content-type': 'text/plain' } }))
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          headers: { 'content-type': 'application/json' },
        }),
      )
      .mockResolvedValueOnce(new Response('blob-content', { headers: { 'content-type': 'application/octet-stream' } }))
      .mockResolvedValueOnce(new Response('raw-content', { headers: { 'content-type': 'text/plain' } }))
      .mockResolvedValueOnce(new Response(null, { status: 204 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ parsed: true }), { headers: { 'content-type': 'application/x-custom' } }))
      .mockResolvedValueOnce(new Response('not-json', { headers: { 'content-type': 'application/x-custom' } }));

    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      fetch: fetchMock,
    });

    await expect(client.request({ path: 'text', responseType: 'text' })).resolves.toBe('plain text');
    await expect(client.request({ path: 'json', responseType: 'json' })).resolves.toEqual({ ok: true });

    const blob = await client.request<Blob>({ path: 'blob', responseType: 'blob' });
    expect(await blob.text()).toBe('blob-content');

    const raw = await client.raw({ path: 'raw' });
    expect(await raw.text()).toBe('raw-content');

    await expect(client.request({ path: 'void', responseType: 'void' })).resolves.toBeUndefined();
    await expect(client.request({ path: 'auto-json' })).resolves.toEqual({ parsed: true });
    await expect(client.request({ path: 'auto-text' })).resolves.toBe('not-json');
  });

  it('supports binary and form-like request bodies', async () => {
    const fetchMock = vi
      .fn<(_input: RequestInfo | URL, _init?: RequestInit) => Promise<Response>>()
      .mockResolvedValueOnce(
        new Response(Uint8Array.from([1, 2, 3]).buffer, {
          headers: { 'content-type': 'application/octet-stream' },
        }),
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ ok: true }), {
          headers: { 'content-type': 'application/json' },
        }),
      );
    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      fetch: fetchMock,
    });

    const arrayBuffer = await client.request<ArrayBuffer, Uint16Array>({
      path: 'binary',
      method: 'PUT',
      body: new Uint16Array([4, 5, 6]),
      responseType: 'arrayBuffer',
    });
    expect(Array.from(new Uint8Array(arrayBuffer))).toEqual([1, 2, 3]);

    await client.request({
      path: 'form',
      method: 'POST',
      body: new URLSearchParams({ hello: 'world' }),
    });

    const binaryHeaders = new Headers(fetchMock.mock.calls[0]?.[1]?.headers);
    expect(binaryHeaders.has('content-type')).toBe(false);
    expect(fetchMock.mock.calls[0]?.[1]?.body).toBeInstanceOf(ArrayBuffer);

    const formHeaders = new Headers(fetchMock.mock.calls[1]?.[1]?.headers);
    expect(formHeaders.has('content-type')).toBe(false);
    expect(fetchMock.mock.calls[1]?.[1]?.body).toBeInstanceOf(URLSearchParams);
  });

  it('wraps non-ok responses in ApiError with parsed bodies', async () => {
    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      fetch: vi.fn(async () => {
        return new Response('failure', {
          status: 418,
          statusText: "I'm a teapot",
          headers: {
            'content-type': 'text/plain',
          },
        });
      }),
    });

    await expect(client.request({ path: 'broken' })).rejects.toMatchObject({
      name: 'ApiError',
      status: 418,
      statusText: "I'm a teapot",
      body: 'failure',
    });
  });

  it('converts AbortError failures into request abort messages', async () => {
    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      fetch: vi.fn(async () => {
        throw new DOMException('The operation was aborted.', 'AbortError');
      }),
    });

    await expect(client.request({ path: 'abort-me' })).rejects.toThrow(
      'Request aborted: The operation was aborted.',
    );
  });

  it('rejects unsupported request body types', async () => {
    const client = new TbdAgentsClient({
      baseUrl: 'https://example.com',
      fetch: vi.fn(async () => {
        return new Response(JSON.stringify({ ok: true }), {
          headers: {
            'content-type': 'application/json',
          },
        });
      }),
    });

    await expect(
      client.request({
        path: 'unsupported',
        body: new Map([['key', 'value']]) as unknown as object,
      }),
    ).rejects.toThrow('Unsupported request body type');
  });
});
