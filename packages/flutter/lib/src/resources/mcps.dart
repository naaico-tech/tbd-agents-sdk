/// MCP servers resource — `/api/mcps`.
library;

import 'base.dart';

class McpsResource extends BaseResource {
  const McpsResource(super.client);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'mcps');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'mcps/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'mcps', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data = await client.request('PUT', 'mcps/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String id) => client.request('DELETE', 'mcps/$id');

  /// `POST /api/mcps/{id}/test` — test the MCP server connection.
  Future<Map<String, dynamic>> test(String id) async {
    final data = await client.request('POST', 'mcps/$id/test');
    return (data as Map<String, dynamic>?) ?? {};
  }

  /// `GET /api/mcps/{id}/tools` — list available tools.
  Future<Map<String, dynamic>> tools(String id) async {
    final data = await client.request('GET', 'mcps/$id/tools');
    return (data as Map<String, dynamic>?) ?? {};
  }
}
