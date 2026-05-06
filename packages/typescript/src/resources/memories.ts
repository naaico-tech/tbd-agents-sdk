import { BaseResource } from './base.js';
import type {
  Memory,
  MemoryCreateInput,
  MemorySearchInput,
  MemoryUpdateInput,
  QueryParams,
} from '../types.js';

export class MemoriesResource extends BaseResource {
  list(query?: QueryParams): Promise<Memory[]> {
    return this.client.request<Memory[]>(
      query
        ? { path: 'memories', query }
        : { path: 'memories' },
    );
  }

  get(id: string): Promise<Memory> {
    return this.client.request<Memory>({ path: `memories/${encodeURIComponent(id)}` });
  }

  create(body: MemoryCreateInput): Promise<Memory> {
    return this.client.request<Memory, MemoryCreateInput>({
      path: 'memories',
      method: 'POST',
      body,
    });
  }

  update(id: string, body: MemoryUpdateInput): Promise<Memory> {
    return this.client.request<Memory, MemoryUpdateInput>({
      path: `memories/${encodeURIComponent(id)}`,
      method: 'PUT',
      body,
    });
  }

  delete(id: string): Promise<void> {
    return this.client.request<void>({
      path: `memories/${encodeURIComponent(id)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }

  search(body: MemorySearchInput): Promise<Memory[]> {
    return this.client.request<Memory[], MemorySearchInput>({
      path: 'memories/search',
      method: 'POST',
      body,
    });
  }

  getStm(agentId: string): Promise<Memory[]> {
    return this.client.request<Memory[]>({
      path: `memories/stm/${encodeURIComponent(agentId)}`,
    });
  }

  get_stm(agentId: string): Promise<Memory[]> {
    return this.getStm(agentId);
  }
}
