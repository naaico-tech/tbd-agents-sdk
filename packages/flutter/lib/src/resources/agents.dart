/// Agents resource — `/api/agents`.
library;

import 'base.dart';

/// Provides CRUD + import/export operations for agents.
class AgentsResource extends BaseResource {
  const AgentsResource(super.client);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'agents');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'agents/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'agents', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data = await client.request('PUT', 'agents/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String id) => client.request('DELETE', 'agents/$id');

  /// `GET /api/agents/export` or `GET /api/agents/{id}/export`
  Future<Map<String, dynamic>> export({String? agentId}) async {
    final path = agentId == null ? 'agents/export' : 'agents/$agentId/export';
    final data = await client.request('GET', path);
    return (data as Map<String, dynamic>?) ?? {};
  }

  /// `POST /api/agents/import`
  Future<Map<String, dynamic>> import_(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'agents/import', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }
}
