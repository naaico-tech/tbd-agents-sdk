import { CollectionResource } from './generic.js';
import type {
  DownloadedKnowledgeItem,
  KnowledgeItem,
  KnowledgeItemCreateInput,
  KnowledgeItemQueryInput,
  KnowledgeItemQueryResponse,
  KnowledgeItemUploadInput,
  QueryParams,
} from '../types.js';

function toBlob(data: KnowledgeItemUploadInput['file'], contentType?: string): Blob {
  if (data instanceof Blob) {
    return data;
  }

  const bytes = data instanceof ArrayBuffer ? new Uint8Array(data) : new Uint8Array(data);

  if (data instanceof ArrayBuffer) {
    return contentType ? new Blob([bytes], { type: contentType }) : new Blob([bytes]);
  }

  return contentType ? new Blob([bytes], { type: contentType }) : new Blob([bytes]);
}

function extractFileName(contentDisposition: string | null): string | undefined {
  if (!contentDisposition) {
    return undefined;
  }

  const match = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(contentDisposition);
  return match?.[1];
}

export class KnowledgeItemsResource extends CollectionResource<
  KnowledgeItem,
  KnowledgeItemCreateInput,
  Partial<KnowledgeItemCreateInput>
> {
  constructor(client: CollectionResource['client']) {
    super(client, 'knowledge-items');
  }

  list(query?: QueryParams): Promise<KnowledgeItem[]> {
    return super.list(query);
  }

  createText(body: KnowledgeItemCreateInput): Promise<KnowledgeItem> {
    return this.create(body);
  }

  async upload(input: KnowledgeItemUploadInput): Promise<KnowledgeItem> {
    const form = new FormData();
    const blob = toBlob(input.file, input.contentType);

    form.append('file', blob, input.fileName ?? 'upload.bin');
    form.append('source_id', input.sourceId);

    if (input.tags?.length) {
      form.append('tags', JSON.stringify(input.tags));
    }

    if (input.metadata) {
      form.append('metadata', JSON.stringify(input.metadata));
    }

    return this.client.request<KnowledgeItem, FormData>({
      path: 'knowledge-items/upload',
      method: 'POST',
      body: form,
    });
  }

  query(body: KnowledgeItemQueryInput): Promise<KnowledgeItemQueryResponse> {
    return this.client.request<KnowledgeItemQueryResponse, KnowledgeItemQueryInput>({
      path: 'knowledge-items/query',
      method: 'POST',
      body,
    });
  }

  async downloadContent(id: string): Promise<DownloadedKnowledgeItem> {
    const response = await this.client.raw({
      path: `knowledge-items/${encodeURIComponent(id)}/content`,
    });

    const arrayBuffer = await response.arrayBuffer();

    const contentType = response.headers.get('content-type') ?? undefined;
    const fileName = extractFileName(response.headers.get('content-disposition'));

    return {
      data: new Uint8Array(arrayBuffer),
      ...(contentType ? { contentType } : {}),
      ...(fileName ? { fileName } : {}),
      response,
    };
  }
}
