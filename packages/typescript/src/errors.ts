export interface ApiErrorOptions {
  message: string;
  status: number;
  statusText: string;
  body?: unknown;
}

export class ApiError extends Error {
  readonly status: number;
  readonly statusText: string;
  readonly body?: unknown;

  constructor(options: ApiErrorOptions) {
    super(options.message);
    this.name = 'ApiError';
    this.status = options.status;
    this.statusText = options.statusText;
    this.body = options.body;
  }
}
