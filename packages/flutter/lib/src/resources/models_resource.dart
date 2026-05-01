/// Models resource — `/api/models`.
library;

import 'base.dart';

class ModelsResource extends BaseResource {
  const ModelsResource(super.client);

  /// `GET /api/models` — list available models.
  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', 'models');
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  /// `GET /api/models/{id}` — fetch a single model.
  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', 'models/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }
}
