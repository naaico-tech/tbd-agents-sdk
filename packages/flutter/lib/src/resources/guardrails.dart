/// Guardrails resource — `/api/guardrails`.
library;

import '../models.dart';
import 'base.dart';

class GuardrailsResource extends BaseResource {
  const GuardrailsResource(super.client);

  Future<List<Guardrail>> list({String? tag}) async {
    final data = await client.request(
      'GET',
      'guardrails',
      queryParameters: tag != null ? {'tag': tag} : null,
    );
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(Guardrail.fromJson).toList();
    }
    return const [];
  }

  Future<Guardrail> get(String id) async {
    final data = await client.request('GET', 'guardrails/$id');
    return Guardrail.fromJson(data as Map<String, dynamic>);
  }

  Future<Guardrail> create(GuardrailCreate payload) async {
    final data = await client.request('POST', 'guardrails', body: payload.toJson());
    return Guardrail.fromJson(data as Map<String, dynamic>);
  }

  Future<Guardrail> update(String id, GuardrailUpdate payload) async {
    final data = await client.request('PUT', 'guardrails/$id', body: payload.toJson());
    return Guardrail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => client.request('DELETE', 'guardrails/$id');
}
