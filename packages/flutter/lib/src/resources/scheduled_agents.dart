/// Scheduled Agents resource — `/api/scheduled-agents`.
library;

import '../models.dart';
import 'base.dart';

class ScheduledAgentsResource extends BaseResource {
  const ScheduledAgentsResource(super.client);

  Future<List<ScheduledAgent>> list() async {
    final data = await client.request('GET', 'scheduled-agents');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(ScheduledAgent.fromJson).toList();
    }
    return const [];
  }

  Future<ScheduledAgent> get(String id) async {
    final data = await client.request('GET', 'scheduled-agents/$id');
    return ScheduledAgent.fromJson(data as Map<String, dynamic>);
  }

  Future<ScheduledAgent> create(ScheduledAgentCreate payload) async {
    final data = await client.request('POST', 'scheduled-agents', body: payload.toJson());
    return ScheduledAgent.fromJson(data as Map<String, dynamic>);
  }

  Future<ScheduledAgent> update(String id, ScheduledAgentUpdate payload) async {
    final data = await client.request('PATCH', 'scheduled-agents/$id', body: payload.toJson());
    return ScheduledAgent.fromJson(data as Map<String, dynamic>);
  }

  Future<ScheduledAgent> enable(String id) async {
    final data = await client.request('PATCH', 'scheduled-agents/$id/enable');
    return ScheduledAgent.fromJson(data as Map<String, dynamic>);
  }

  Future<ScheduledAgent> disable(String id) async {
    final data = await client.request('PATCH', 'scheduled-agents/$id/disable');
    return ScheduledAgent.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => client.request('DELETE', 'scheduled-agents/$id');
}
