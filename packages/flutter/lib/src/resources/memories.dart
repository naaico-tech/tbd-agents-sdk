/// Memories resource — `/api/memories`.
library;

import '../models.dart';
import 'base.dart';

class MemoriesResource extends BaseResource {
  const MemoriesResource(super.client);

  Future<List<Memory>> list({
    String? agentId,
    String? scope,
  }) async {
    final query = <String, String>{};
    if (agentId != null) query['agent_id'] = agentId;
    if (scope != null) query['scope'] = scope;
    final data = await client.request(
      'GET',
      'memories',
      queryParameters: query.isEmpty ? null : query,
    );
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    return const [];
  }

  Future<Memory> get(String id) async {
    final data = await client.request('GET', 'memories/$id');
    return Memory.fromJson(data as Map<String, dynamic>);
  }

  Future<Memory> create(MemoryCreate payload) async {
    final data = await client.request('POST', 'memories', body: payload.toJson());
    return Memory.fromJson(data as Map<String, dynamic>);
  }

  Future<Memory> update(String id, MemoryUpdate payload) async {
    final data = await client.request('PUT', 'memories/$id', body: payload.toJson());
    return Memory.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => client.request('DELETE', 'memories/$id');

  Future<List<Memory>> search(MemorySearchRequest payload) async {
    final data = await client.request('POST', 'memories/search', body: payload.toJson());
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    return const [];
  }

  Future<List<Memory>> getStm(String agentId) async {
    final data = await client.request('GET', 'memories/stm/$agentId');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Memory.fromJson).toList();
    }
    return const [];
  }
}
