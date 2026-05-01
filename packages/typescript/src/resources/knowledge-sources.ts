import { CollectionResource } from './generic.js';
import type {
  KnowledgeSource,
  KnowledgeSourceCreateInput,
  KnowledgeSourceTestResponse,
  KnowledgeSourceUpdateInput,
} from '../types.js';

export class KnowledgeSourcesResource extends CollectionResource<
  KnowledgeSource,
  KnowledgeSourceCreateInput,
  KnowledgeSourceUpdateInput
> {
  constructor(client: CollectionResource['client']) {
    super(client, 'knowledge-sources');
  }

  test(id: string): Promise<KnowledgeSourceTestResponse> {
    return this.client.request<KnowledgeSourceTestResponse>({
      path: `knowledge-sources/${encodeURIComponent(id)}/test`,
      method: 'POST',
    });
  }
}
