/// Knowledge sources resource — `/api/knowledge-sources`.
library;

import 'base.dart';

class KnowledgeSourcesResource extends BaseResource {
  const KnowledgeSourcesResource(super.client);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'knowledge-sources');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'knowledge-sources/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data =
        await client.request('POST', 'knowledge-sources', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data =
        await client.request('PUT', 'knowledge-sources/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String id) =>
      client.request('DELETE', 'knowledge-sources/$id');

  /// `POST /api/knowledge-sources/{id}/test` — verify connectivity.
  Future<Map<String, dynamic>> test(String id) async {
    final data =
        await client.request('POST', 'knowledge-sources/$id/test');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> export({String? sourceId}) async {
    final path = sourceId == null
        ? 'knowledge-sources/export'
        : 'knowledge-sources/$sourceId/export';
    final data = await client.request('GET', path);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> import_(Map<String, dynamic> payload) async {
    final data =
        await client.request('POST', 'knowledge-sources/import', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }
}
