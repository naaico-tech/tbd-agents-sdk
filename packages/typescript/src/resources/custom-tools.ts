import { BaseResource } from './base.js';
import type {
  CustomTool,
  CustomToolCreateInput,
  CustomToolRunInput,
  CustomToolRunResponse,
  CustomToolUpdateInput,
  CustomToolUploadInput,
  CustomToolValidateInput,
  CustomToolValidateResponse,
  EnvMappingResponse,
  EnvMappingUpdateInput,
  QueryParams,
} from '../types.js';

export class CustomToolsResource extends BaseResource {
  list(query?: QueryParams): Promise<CustomTool[]> {
    return this.client.request<CustomTool[]>(
      query
        ? { path: 'custom-tools', query }
        : { path: 'custom-tools' },
    );
  }

  get(id: string): Promise<CustomTool> {
    return this.client.request<CustomTool>({ path: `custom-tools/${encodeURIComponent(id)}` });
  }

  create(body: CustomToolCreateInput): Promise<CustomTool> {
    return this.client.request<CustomTool, CustomToolCreateInput>({
      path: 'custom-tools',
      method: 'POST',
      body,
    });
  }

  update(id: string, body: CustomToolUpdateInput): Promise<CustomTool> {
    return this.client.request<CustomTool, CustomToolUpdateInput>({
      path: `custom-tools/${encodeURIComponent(id)}`,
      method: 'PUT',
      body,
    });
  }

  delete(id: string): Promise<void> {
    return this.client.request<void>({
      path: `custom-tools/${encodeURIComponent(id)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }

  run(id: string, body: CustomToolRunInput): Promise<CustomToolRunResponse> {
    return this.client.request<CustomToolRunResponse, CustomToolRunInput>({
      path: `custom-tools/${encodeURIComponent(id)}/run`,
      method: 'POST',
      body,
    });
  }

  validate(body: CustomToolValidateInput): Promise<CustomToolValidateResponse> {
    return this.client.request<CustomToolValidateResponse, CustomToolValidateInput>({
      path: 'custom-tools/validate',
      method: 'POST',
      body,
    });
  }

  async upload(input: CustomToolUploadInput): Promise<CustomTool> {
    const { file, fileName = 'tool.py', name, description = '', tags = [] } = input;
    const form = new FormData();

    let blob: Blob;
    if (file instanceof Blob) {
      blob = file;
    } else if (file instanceof Uint8Array) {
      blob = new Blob([file.buffer as ArrayBuffer], { type: 'text/plain' });
    } else {
      blob = new Blob([file as ArrayBuffer], { type: 'text/plain' });
    }

    form.append('file', blob, fileName);
    form.append('name', name);
    form.append('description', description);
    form.append('tags', JSON.stringify(tags));

    const response = await this.client.raw({
      path: 'custom-tools/upload',
      method: 'POST',
      body: form as unknown as Record<string, unknown>,
    });

    if (!response.ok) {
      throw new Error(`Upload failed: ${response.status} ${response.statusText}`);
    }

    return response.json() as Promise<CustomTool>;
  }

  getEnvMapping(id: string): Promise<EnvMappingResponse> {
    return this.client.request<EnvMappingResponse>({
      path: `custom-tools/${encodeURIComponent(id)}/env-mapping`,
    });
  }

  get_env_mapping(id: string): Promise<EnvMappingResponse> {
    return this.getEnvMapping(id);
  }

  updateEnvMapping(id: string, body: EnvMappingUpdateInput): Promise<EnvMappingResponse> {
    return this.client.request<EnvMappingResponse, EnvMappingUpdateInput>({
      path: `custom-tools/${encodeURIComponent(id)}/env-mapping`,
      method: 'PUT',
      body,
    });
  }

  update_env_mapping(id: string, body: EnvMappingUpdateInput): Promise<EnvMappingResponse> {
    return this.updateEnvMapping(id, body);
  }
}
