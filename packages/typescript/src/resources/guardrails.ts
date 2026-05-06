import { BaseResource } from './base.js';
import type {
  Guardrail,
  GuardrailCreateInput,
  GuardrailUpdateInput,
  QueryParams,
} from '../types.js';

export class GuardrailsResource extends BaseResource {
  list(query?: QueryParams): Promise<Guardrail[]> {
    return this.client.request<Guardrail[]>(
      query
        ? { path: 'guardrails', query }
        : { path: 'guardrails' },
    );
  }

  get(id: string): Promise<Guardrail> {
    return this.client.request<Guardrail>({ path: `guardrails/${encodeURIComponent(id)}` });
  }

  create(body: GuardrailCreateInput): Promise<Guardrail> {
    return this.client.request<Guardrail, GuardrailCreateInput>({
      path: 'guardrails',
      method: 'POST',
      body,
    });
  }

  update(id: string, body: GuardrailUpdateInput): Promise<Guardrail> {
    return this.client.request<Guardrail, GuardrailUpdateInput>({
      path: `guardrails/${encodeURIComponent(id)}`,
      method: 'PUT',
      body,
    });
  }

  delete(id: string): Promise<void> {
    return this.client.request<void>({
      path: `guardrails/${encodeURIComponent(id)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }
}
