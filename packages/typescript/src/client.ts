import { ApiError } from './errors.js';
import { HealthResource } from './resources/health.js';
import { CollectionResource } from './resources/generic.js';
import { KnowledgeItemsResource } from './resources/knowledge-items.js';
import { KnowledgeSourcesResource } from './resources/knowledge-sources.js';
import { TasksResource } from './resources/tasks.js';
import { WorkflowsResource } from './resources/workflows.js';
import type {
  FetchLike,
  JsonValue,
  QueryParams,
  RequestHeaders,
  RequestMethod,
  ResourceRecord,
} from './types.js';

export type TokenProvider = string | (() => string | Promise<string>);
export type ResponseType = 'auto' | 'arrayBuffer' | 'blob' | 'json' | 'raw' | 'text' | 'void';

export interface RequestOptions<TBody = unknown> {
  path: string;
  method?: RequestMethod;
  query?: QueryParams;
  body?: TBody;
  headers?: RequestHeaders;
  timeoutMs?: number;
  signal?: AbortSignal;
  api?: boolean;
  responseType?: ResponseType;
}

export interface TbdAgentsClientConfig {
  baseUrl: string;
  token: TokenProvider;
  fetch?: FetchLike;
  timeoutMs?: number;
  headers?: RequestHeaders;
}

function normalizeBaseUrl(baseUrl: string): string {
  return baseUrl.replace(/\/+$/, '');
}

function isAbsoluteUrl(value: string): boolean {
  return /^https?:\/\//i.test(value);
}

function isFormData(value: unknown): value is FormData {
  return typeof FormData !== 'undefined' && value instanceof FormData;
}

function isBlob(value: unknown): value is Blob {
  return typeof Blob !== 'undefined' && value instanceof Blob;
}

function isUrlSearchParams(value: unknown): value is URLSearchParams {
  return typeof URLSearchParams !== 'undefined' && value instanceof URLSearchParams;
}

function isArrayBufferView(value: unknown): value is ArrayBufferView {
  return ArrayBuffer.isView(value);
}

function isJsonSerializable(value: unknown): value is JsonValue {
  if (value === null) {
    return true;
  }

  if (Array.isArray(value)) {
    return value.every(isJsonSerializable);
  }

  switch (typeof value) {
    case 'boolean':
    case 'number':
    case 'string':
      return true;
    case 'object':
      return !isBlob(value) && !isFormData(value) && !isUrlSearchParams(value) && !isArrayBufferView(value) && !(value instanceof ArrayBuffer);
    default:
      return false;
  }
}

async function defaultParseResponse(response: Response): Promise<unknown> {
  if (response.status === 204) {
    return undefined;
  }

  const contentType = response.headers.get('content-type') ?? '';

  if (contentType.includes('application/json')) {
    return response.json();
  }

  if (contentType.startsWith('text/')) {
    return response.text();
  }

  if (contentType.includes('application/octet-stream')) {
    return response.arrayBuffer();
  }

  const bodyText = await response.text();
  if (!bodyText) {
    return undefined;
  }

  try {
    return JSON.parse(bodyText);
  } catch {
    return bodyText;
  }
}

function appendQueryParams(url: URL, query?: QueryParams): void {
  if (!query) {
    return;
  }

  for (const [key, rawValue] of Object.entries(query)) {
    if (rawValue === undefined || rawValue === null) {
      continue;
    }

    const values = Array.isArray(rawValue) ? rawValue : [rawValue];

    for (const value of values) {
      if (value === undefined || value === null) {
        continue;
      }

      const normalizedValue = value instanceof Date ? value.toISOString() : String(value);
      url.searchParams.append(key, normalizedValue);
    }
  }
}

function joinPath(baseUrl: string, path: string, api: boolean): URL {
  if (isAbsoluteUrl(path)) {
    return new URL(path);
  }

  const rootUrl = `${baseUrl}/`;
  const apiUrl = `${baseUrl}/api/`;
  const normalizedPath = api ? path.replace(/^\/+/, '') : path;

  return new URL(normalizedPath, api ? apiUrl : rootUrl);
}

function createAbortController(signal?: AbortSignal, timeoutMs?: number): {
  controller: AbortController;
  cleanup: () => void;
} {
  const controller = new AbortController();
  const cleanups: Array<() => void> = [];

  if (signal) {
    if (signal.aborted) {
      controller.abort(signal.reason);
    } else {
      const onAbort = () => controller.abort(signal.reason);
      signal.addEventListener('abort', onAbort, { once: true });
      cleanups.push(() => signal.removeEventListener('abort', onAbort));
    }
  }

  if (timeoutMs && timeoutMs > 0) {
    const timer = setTimeout(() => {
      controller.abort(new Error(`Request timed out after ${timeoutMs}ms`));
    }, timeoutMs);
    cleanups.push(() => clearTimeout(timer));
  }

  return {
    controller,
    cleanup: () => {
      for (const cleanup of cleanups) {
        cleanup();
      }
    },
  };
}

export class TbdAgentsClient {
  readonly baseUrl: string;
  readonly timeoutMs: number;
  readonly defaultHeaders: RequestHeaders;

  readonly health: HealthResource;
  readonly agents: CollectionResource<ResourceRecord>;
  readonly skills: CollectionResource<ResourceRecord>;
  readonly mcps: CollectionResource<ResourceRecord>;
  readonly knowledgeSources: KnowledgeSourcesResource;
  readonly knowledge_sources: KnowledgeSourcesResource;
  readonly knowledgeItems: KnowledgeItemsResource;
  readonly knowledge_items: KnowledgeItemsResource;
  readonly workflows: WorkflowsResource;
  readonly tasks: TasksResource;
  readonly providers: CollectionResource<ResourceRecord>;
  readonly tokens: CollectionResource<ResourceRecord>;
  readonly models: CollectionResource<ResourceRecord>;

  private readonly fetchImpl: FetchLike;
  private readonly tokenProvider: TokenProvider;

  constructor(config: TbdAgentsClientConfig) {
    if (!config.baseUrl) {
      throw new Error('baseUrl is required');
    }

    if (!config.token) {
      throw new Error('token is required');
    }

    if (!config.fetch && typeof fetch === 'undefined') {
      throw new Error('A fetch implementation is required in this runtime');
    }

    this.baseUrl = normalizeBaseUrl(config.baseUrl);
    this.timeoutMs = config.timeoutMs ?? 30_000;
    this.defaultHeaders = config.headers ?? {};
    this.fetchImpl = config.fetch ?? fetch;
    this.tokenProvider = config.token;

    this.health = new HealthResource(this);
    this.agents = new CollectionResource(this, 'agents');
    this.skills = new CollectionResource(this, 'skills');
    this.mcps = new CollectionResource(this, 'mcps');
    this.knowledgeSources = new KnowledgeSourcesResource(this);
    this.knowledge_sources = this.knowledgeSources;
    this.knowledgeItems = new KnowledgeItemsResource(this);
    this.knowledge_items = this.knowledgeItems;
    this.workflows = new WorkflowsResource(this);
    this.tasks = new TasksResource(this);
    this.providers = new CollectionResource(this, 'providers');
    this.tokens = new CollectionResource(this, 'tokens');
    this.models = new CollectionResource(this, 'models');
  }

  async request<TResponse = unknown, TBody = unknown>(
    options: RequestOptions<TBody>,
  ): Promise<TResponse> {
    const token = await this.resolveToken();
    const url = joinPath(this.baseUrl, options.path, options.api ?? true);
    appendQueryParams(url, options.query);

    const headers = new Headers();

    for (const [key, value] of Object.entries(this.defaultHeaders)) {
      if (value !== undefined) {
        headers.set(key, value);
      }
    }

    headers.set('authorization', `Bearer ${token}`);
    headers.set('accept', headers.get('accept') ?? 'application/json');

    if (options.headers) {
      for (const [key, value] of Object.entries(options.headers)) {
        if (value === undefined) {
          continue;
        }
        headers.set(key, value);
      }
    }

    let body: BodyInit | undefined;

    if (options.body !== undefined) {
      if (isFormData(options.body) || isBlob(options.body) || isUrlSearchParams(options.body)) {
        body = options.body;
      } else if (typeof options.body === 'string') {
        body = options.body;
      } else if (options.body instanceof ArrayBuffer) {
        body = options.body;
      } else if (isArrayBufferView(options.body)) {
        body = Uint8Array.from(options.body as unknown as ArrayLike<number>).buffer;
      } else if (isJsonSerializable(options.body)) {
        body = JSON.stringify(options.body);
        if (!headers.has('content-type')) {
          headers.set('content-type', 'application/json');
        }
      } else {
        throw new Error('Unsupported request body type');
      }
    }

    const { controller, cleanup } = createAbortController(options.signal, options.timeoutMs ?? this.timeoutMs);

    try {
      const init: RequestInit = {
        method: options.method ?? (body === undefined ? 'GET' : 'POST'),
        headers,
        signal: controller.signal,
      };

      if (body !== undefined) {
        init.body = body;
      }

      const response = await this.fetchImpl(url, init);

      if (!response.ok) {
        throw new ApiError({
          message: `Request failed with status ${response.status}`,
          status: response.status,
          statusText: response.statusText,
          body: await defaultParseResponse(response.clone()),
        });
      }

      switch (options.responseType ?? 'auto') {
        case 'raw':
          return response as TResponse;
        case 'void':
          return undefined as TResponse;
        case 'text':
          return (await response.text()) as TResponse;
        case 'json':
          return (await response.json()) as TResponse;
        case 'blob':
          return (await response.blob()) as TResponse;
        case 'arrayBuffer':
          return (await response.arrayBuffer()) as TResponse;
        case 'auto':
        default:
          return (await defaultParseResponse(response)) as TResponse;
      }
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error(`Request aborted: ${error.message}`);
      }

      throw error;
    } finally {
      cleanup();
    }
  }

  raw(options: Omit<RequestOptions, 'responseType'>): Promise<Response> {
    return this.request<Response>({ ...options, responseType: 'raw' });
  }

  private async resolveToken(): Promise<string> {
    const token = typeof this.tokenProvider === 'function'
      ? await this.tokenProvider()
      : this.tokenProvider;

    if (!token) {
      throw new Error('Resolved token is empty');
    }

    return token;
  }
}
