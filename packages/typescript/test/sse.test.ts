import { describe, expect, it } from 'vitest';
import { parseSseStream } from '../src/sse.js';

function createStream(chunks: string[]): ReadableStream<Uint8Array> {
  return new ReadableStream<Uint8Array>({
    start(controller) {
      for (const chunk of chunks) {
        controller.enqueue(new TextEncoder().encode(chunk));
      }
      controller.close();
    },
  });
}

describe('parseSseStream', () => {
  it('parses JSON payloads across chunk boundaries', async () => {
    const stream = createStream([
      'data: {"id":"evt_1","type":"status","data":{"status":"running"}',
      ',"timestamp":"2026-01-01T00:00:00Z"}\n\n',
      ': keepalive\n\n',
      'data: {"id":"evt_2","type":"message_delta","data":{"delta":"hel',
      'lo"},"timestamp":"2026-01-01T00:00:01Z"}\n\n',
    ]);

    const events: Array<{ id: string; type: string; data: unknown; timestamp: string }> = [];

    for await (const message of parseSseStream(stream, {
      parser: (value) => JSON.parse(value) as { id: string; type: string; data: unknown; timestamp: string },
    })) {
      events.push(message.data);
    }

    expect(events).toEqual([
      {
        id: 'evt_1',
        type: 'status',
        data: { status: 'running' },
        timestamp: '2026-01-01T00:00:00Z',
      },
      {
        id: 'evt_2',
        type: 'message_delta',
        data: { delta: 'hello' },
        timestamp: '2026-01-01T00:00:01Z',
      },
    ]);
  });

  it('supports standard SSE fields and multiline data', async () => {
    const stream = createStream([
      'id: 42\n',
      'event: usage\n',
      'data: {"total_input_tokens":10,\n',
      'data: "total_output_tokens":20}\n\n',
    ]);

    const messages = [];

    for await (const message of parseSseStream(stream)) {
      messages.push(message);
    }

    expect(messages).toEqual([
      {
        id: '42',
        event: 'usage',
        retry: undefined,
        data: '{"total_input_tokens":10,\n"total_output_tokens":20}',
      },
    ]);
  });
});
