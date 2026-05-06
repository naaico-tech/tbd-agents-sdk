import { BaseResource } from './base.js';
import { parseSseStream } from '../sse.js';
import type {
  ChatInput,
  ChatMessageRecord,
  ChatSessionDetail,
  ChatSessionResponse,
  ChatStartInput,
  ChatStartResponse,
} from '../types.js';

export class ChatResource extends BaseResource {
  async *sendMessage(
    agentId: string,
    body: ChatInput,
    signal?: AbortSignal,
  ): AsyncGenerator<{ data: string }> {
    const response = await this.client.raw(
      signal
        ? {
            path: `agents/${encodeURIComponent(agentId)}/chat`,
            method: 'POST',
            body: body as unknown as Record<string, unknown>,
            signal,
          }
        : {
            path: `agents/${encodeURIComponent(agentId)}/chat`,
            method: 'POST',
            body: body as unknown as Record<string, unknown>,
          },
    );

    if (!response.ok) {
      throw new Error(`Chat request failed: ${response.status} ${response.statusText}`);
    }

    yield* parseSseStream<string>(response, { parser: (v) => v });
  }

  /** Snake-case alias for {@link sendMessage}. */
  send_message(
    agentId: string,
    body: ChatInput,
    signal?: AbortSignal,
  ): AsyncGenerator<{ data: string }> {
    return this.sendMessage(agentId, body, signal);
  }

  listSessions(agentId: string): Promise<ChatSessionResponse[]> {
    return this.client.request<ChatSessionResponse[]>({
      path: `agents/${encodeURIComponent(agentId)}/chat/sessions`,
    });
  }

  list_sessions(agentId: string): Promise<ChatSessionResponse[]> {
    return this.listSessions(agentId);
  }

  getSession(agentId: string, sessionId: string): Promise<ChatSessionDetail> {
    return this.client.request<ChatSessionDetail>({
      path: `agents/${encodeURIComponent(agentId)}/chat/sessions/${encodeURIComponent(sessionId)}`,
    });
  }

  get_session(agentId: string, sessionId: string): Promise<ChatSessionDetail> {
    return this.getSession(agentId, sessionId);
  }

  deleteSession(agentId: string, sessionId: string): Promise<void> {
    return this.client.request<void>({
      path: `agents/${encodeURIComponent(agentId)}/chat/sessions/${encodeURIComponent(sessionId)}`,
      method: 'DELETE',
      responseType: 'void',
    });
  }

  delete_session(agentId: string, sessionId: string): Promise<void> {
    return this.deleteSession(agentId, sessionId);
  }

  start(body: ChatStartInput): Promise<ChatStartResponse> {
    return this.client.request<ChatStartResponse, ChatStartInput>({
      path: 'chat/start',
      method: 'POST',
      body,
    });
  }
}
