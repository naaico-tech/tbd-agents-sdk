/// Export / Import resource — `/api/export` and `/api/import`.
library;

import '../models.dart';
import 'base.dart';

class ExportImportResource extends BaseResource {
  const ExportImportResource(super.client);

  Future<FullExportBundle> exportAll() async {
    final data = await client.request('GET', 'export');
    return FullExportBundle.fromJson(data as Map<String, dynamic>);
  }

  Future<BundleImportResult> importAll(FullExportBundle payload) async {
    final data = await client.request('POST', 'import', body: payload.toJson());
    return BundleImportResult.fromJson(data as Map<String, dynamic>);
  }
}
