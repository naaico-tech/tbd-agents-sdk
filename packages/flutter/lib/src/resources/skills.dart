/// Skills resource — `/api/skills`.
library;

import 'base.dart';

class SkillsResource extends BaseResource {
  const SkillsResource(super.client);

  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'skills');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'skills/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'skills', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data = await client.request('PUT', 'skills/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<void> delete(String id) => client.request('DELETE', 'skills/$id');

  Future<Map<String, dynamic>> export({String? skillId}) async {
    final path = skillId == null ? 'skills/export' : 'skills/$skillId/export';
    final data = await client.request('GET', path);
    return (data as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> import_(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'skills/import', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }
}
