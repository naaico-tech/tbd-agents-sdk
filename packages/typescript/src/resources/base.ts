import type { TbdAgentsClient } from '../client.js';

export interface PollOptions<TValue> {
  intervalMs?: number;
  timeoutMs?: number;
  signal?: AbortSignal;
  predicate: (value: TValue) => boolean;
}

function delay(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(signal.reason instanceof Error ? signal.reason : new Error('Polling aborted'));
      return;
    }

    const timer = setTimeout(resolve, ms);

    if (signal) {
      const onAbort = () => {
        clearTimeout(timer);
        reject(signal.reason instanceof Error ? signal.reason : new Error('Polling aborted'));
      };

      signal.addEventListener('abort', onAbort, { once: true });
    }
  });
}

export async function pollUntil<TValue>(
  fetcher: () => Promise<TValue>,
  options: PollOptions<TValue>,
): Promise<TValue> {
  const startedAt = Date.now();
  const intervalMs = options.intervalMs ?? 1_000;
  const timeoutMs = options.timeoutMs ?? 60_000;

  while (true) {
    const value = await fetcher();
    if (options.predicate(value)) {
      return value;
    }

    if (Date.now() - startedAt >= timeoutMs) {
      throw new Error(`Polling timed out after ${timeoutMs}ms`);
    }

    await delay(intervalMs, options.signal);
  }
}

export class BaseResource {
  protected readonly client: TbdAgentsClient;

  constructor(client: TbdAgentsClient) {
    this.client = client;
  }
}
