import { BaseResource } from './base.js';
import type { BundleImportResult, FullExportBundle } from '../types.js';

export class ExportImportResource extends BaseResource {
  exportAll(): Promise<FullExportBundle> {
    return this.client.request<FullExportBundle>({ path: 'export' });
  }

  export_all(): Promise<FullExportBundle> {
    return this.exportAll();
  }

  importAll(body: FullExportBundle): Promise<BundleImportResult> {
    return this.client.request<BundleImportResult, FullExportBundle>({
      path: 'import',
      method: 'POST',
      body,
    });
  }

  import_all(body: FullExportBundle): Promise<BundleImportResult> {
    return this.importAll(body);
  }
}
