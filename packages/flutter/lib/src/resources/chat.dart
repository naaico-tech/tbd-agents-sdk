/// Chat resource — `/api/agents/{id}/chat` and `/api/chat/start`.
library;

import 'dart:async';

import '../models.dart';
import '../sse.dart';
import 'base.dart';

class ChatResource extends BaseResource {
  const ChatResource(super.client);

  /// Streams SSE messages from POST /api/agents/{agentId}/chat.
  Stream<String> sendMessage(String agentId, ChatRequest payload) async* {
    final streamed = await client.streamRequest(
      'POST',
      'agents/$agentId/chat',
      body: payload.toJson(),
    );
    await for (final message in parseSseStream(streamed.stream)) {
      if (message.data.isNotEmpty) {
        yield message.data;
      }
    }
  }

  Future<List<ChatSessionResponse>> listSessions(String agentId) async {
    final data = await client.request('GET', 'agents/$agentId/chat/sessions');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChatSessionResponse.fromJson)
          .toList();
    }
    return const [];
  }

  Future<ChatSessionDetail> getSession(String agentId, String sessionId) async {
    final data = await client.request(
      'GET',
      'agents/$agentId/chat/sessions/$sessionId',
    );
    return ChatSessionDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String agentId, String sessionId) =>
      client.request('DELETE', 'agents/$agentId/chat/sessions/$sessionId');

  Future<ChatStartResponse> start(ChatStartRequest payload) async {
    final data = await client.request('POST', 'chat/start', body: payload.toJson());
    return ChatStartResponse.fromJson(data as Map<String, dynamic>);
  }
}
