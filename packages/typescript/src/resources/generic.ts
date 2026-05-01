import { BaseResource } from './base.js';
import type { QueryParams, ResourceRecord } from '../types.js';

export class CollectionResource<
  TItem extends ResourceRecord = ResourceRecord,
  TCreate = Partial<TItem>,
  TUpdate = Partial<TItem>,
> extends BaseResource {
  protected readonly resourcePath: string;

  constructor(client: BaseResource['client'], resourcePath: string) {
    super(client);
    this.resourcePath = resourcePath;
  }

  list(query?: QueryParams): Promise<TItem[]> {
    return this.client.request<TItem[]>(
      query
        ? {
            path: this.resourcePath,
            query,
          }
        : {
            path: this.resourcePath,
          },
    );
  }

  get(id: string): Promise<TItem> {
    return this.client.request<TItem>({
      path: `${this.resourcePath}/${encodeURIComponent(id)}`,
    });
  }

  create(body: TCreate): Promise<TItem> {
    return this.client.request<TItem, TCreate>({
      path: this.resourcePath,
      method: 'POST',
      body,
    });
  }

  update(id: string, body: TUpdate): Promise<TItem> {
    return this.client.request<TItem, TUpdate>({
      path: `${this.resourcePath}/${encodeURIComponent(id)}`,
      method: 'PUT',
      body,
    });
  }

  delete(id: string): Promise<void> {
    return this.client.request<void>({
      path: `${this.resourcePath}/${encodeURIComponent(id)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }
}
