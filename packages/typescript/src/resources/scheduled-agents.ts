import { BaseResource } from './base.js';
import type {
  ScheduledAgent,
  ScheduledAgentCreateInput,
  ScheduledAgentUpdateInput,
} from '../types.js';

export class ScheduledAgentsResource extends BaseResource {
  list(): Promise<ScheduledAgent[]> {
    return this.client.request<ScheduledAgent[]>({ path: 'scheduled-agents' });
  }

  get(id: string): Promise<ScheduledAgent> {
    return this.client.request<ScheduledAgent>({ path: `scheduled-agents/${encodeURIComponent(id)}` });
  }

  create(body: ScheduledAgentCreateInput): Promise<ScheduledAgent> {
    return this.client.request<ScheduledAgent, ScheduledAgentCreateInput>({
      path: 'scheduled-agents',
      method: 'POST',
      body,
    });
  }

  update(id: string, body: ScheduledAgentUpdateInput): Promise<ScheduledAgent> {
    return this.client.request<ScheduledAgent, ScheduledAgentUpdateInput>({
      path: `scheduled-agents/${encodeURIComponent(id)}`,
      method: 'PATCH',
      body,
    });
  }

  enable(id: string): Promise<ScheduledAgent> {
    return this.client.request<ScheduledAgent>({
      path: `scheduled-agents/${encodeURIComponent(id)}/enable`,
      method: 'PATCH',
    });
  }

  disable(id: string): Promise<ScheduledAgent> {
    return this.client.request<ScheduledAgent>({
      path: `scheduled-agents/${encodeURIComponent(id)}/disable`,
      method: 'PATCH',
    });
  }

  delete(id: string): Promise<void> {
    return this.client.request<void>({
      path: `scheduled-agents/${encodeURIComponent(id)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }
}
