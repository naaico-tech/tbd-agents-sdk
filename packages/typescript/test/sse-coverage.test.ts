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

describe('parseSseStream edge cases', () => {
  it('ignores empty events and invalid retry values', async () => {
    const stream = createStream([
      ': keepalive\n\n',
      'event: update\n',
      'retry: not-a-number\n',
      'data: hello\n\n',
      'id\n\n',
    ]);

    const messages = [];
    for await (const message of parseSseStream(stream)) {
      messages.push(message);
    }

    expect(messages).toEqual([
      {
        event: 'update',
        data: 'hello',
      },
    ]);
  });

  it('throws when an SSE response has no body', async () => {
    await expect(parseSseStream(new Response(null)).next()).rejects.toThrow('SSE response body is empty');
  });
});
