/// Tokens resource — `/api/tokens`.
library;

import 'base.dart';

class TokensResource extends BaseResource {
  const TokensResource(super.client);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'tokens');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'tokens/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'tokens', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data = await client.request('PUT', 'tokens/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String id) =>
      client.request('DELETE', 'tokens/$id');
}
