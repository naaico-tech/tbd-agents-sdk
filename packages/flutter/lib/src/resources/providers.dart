/// Providers resource — `/api/providers`.
library;

import 'base.dart';

class ProvidersResource extends BaseResource {
  const ProvidersResource(super.client);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'providers');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'providers/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'providers', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data = await client.request('PUT', 'providers/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String id) =>
      client.request('DELETE', 'providers/$id');
}
