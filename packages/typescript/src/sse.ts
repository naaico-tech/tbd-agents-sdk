export interface SseMessage<TData = unknown> {
  id?: string;
  event?: string;
  retry?: number;
  data: TData;
}

export interface SseParserOptions<TData> {
  parser?: (value: string) => TData;
}

function parseEventBlock<TData>(
  block: string,
  parser: (value: string) => TData,
): SseMessage<TData> | undefined {
  const lines = block.split(/\r?\n/);
  const dataLines: string[] = [];
  let id: string | undefined;
  let event: string | undefined;
  let retry: number | undefined;

  for (const line of lines) {
    if (!line || line.startsWith(':')) {
      continue;
    }

    const separatorIndex = line.indexOf(':');
    const field = separatorIndex === -1 ? line : line.slice(0, separatorIndex);
    const rawValue = separatorIndex === -1 ? '' : line.slice(separatorIndex + 1).replace(/^ /, '');

    switch (field) {
      case 'data':
        dataLines.push(rawValue);
        break;
      case 'id':
        id = rawValue;
        break;
      case 'event':
        event = rawValue;
        break;
      case 'retry':
        retry = Number(rawValue);
        break;
      default:
        break;
    }
  }

  if (!dataLines.length) {
    return undefined;
  }

  const parsedRetry = Number.isFinite(retry) ? retry : undefined;

  return {
    ...(id ? { id } : {}),
    ...(event ? { event } : {}),
    ...(parsedRetry !== undefined ? { retry: parsedRetry } : {}),
    data: parser(dataLines.join('\n')),
  };
}

function getStream(source: Response | ReadableStream<Uint8Array>): ReadableStream<Uint8Array> {
  if (source instanceof Response) {
    if (!source.body) {
      throw new Error('SSE response body is empty');
    }
    return source.body;
  }

  return source;
}

export async function* parseSseStream<TData = string>(
  source: Response | ReadableStream<Uint8Array>,
  options?: SseParserOptions<TData>,
): AsyncGenerator<SseMessage<TData>, void, void> {
  const stream = getStream(source);
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  const parser = options?.parser ?? ((value: string) => value as TData);
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    buffer += decoder.decode(value, { stream: !done });

    const parts = buffer.split(/\r?\n\r?\n/);
    buffer = parts.pop() ?? '';

    for (const part of parts) {
      const event = parseEventBlock(part, parser);
      if (event) {
        yield event;
      }
    }

    if (done) {
      if (buffer.trim()) {
        const event = parseEventBlock(buffer, parser);
        if (event) {
          yield event;
        }
      }
      break;
    }
  }
}
