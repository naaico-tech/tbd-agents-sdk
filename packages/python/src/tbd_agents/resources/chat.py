from __future__ import annotations

from collections.abc import Iterator
from typing import Any, Mapping

from tbd_agents._sse import iter_sse_messages
from tbd_agents._utils import serialize_payload
from tbd_agents.types import (
    ChatMessageRecord,
    ChatRequest,
    ChatSessionDetail,
    ChatSessionResponse,
    ChatStartRequest,
    ChatStartResponse,
)

from .base import BaseResource


class ChatResource(BaseResource):
    def send_message(
        self,
        agent_id: str,
        payload: ChatRequest | Mapping[str, Any],
    ) -> Iterator[str]:
        """POST /api/agents/{id}/chat — streams SSE data frames."""
        with self._client.stream(
            "POST",
            f"/agents/{agent_id}/chat",
            json=serialize_payload(payload),
        ) as response:
            self._client.raise_for_status(response)
            for message in iter_sse_messages(response.iter_lines()):
                if message.data:
                    yield message.data

    def list_sessions(self, agent_id: str) -> list[ChatSessionResponse]:
        return self._get_list(f"/agents/{agent_id}/chat/sessions", model=ChatSessionResponse)

    def get_session(self, agent_id: str, session_id: str) -> ChatSessionDetail:
        return self._get(f"/agents/{agent_id}/chat/sessions/{session_id}", model=ChatSessionDetail)

    def delete_session(self, agent_id: str, session_id: str) -> None:
        self._delete(f"/agents/{agent_id}/chat/sessions/{session_id}")

    def start(self, payload: ChatStartRequest | Mapping[str, Any]) -> ChatStartResponse:
        return self._post("/chat/start", payload, model=ChatStartResponse)
