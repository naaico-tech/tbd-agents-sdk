import { BaseResource } from './base.js';
import type { HealthResponse } from '../types.js';

export class HealthResource extends BaseResource {
  check(): Promise<HealthResponse> {
    return this.client.request<HealthResponse>({
      path: '/health',
      api: false,
    });
  }
}
