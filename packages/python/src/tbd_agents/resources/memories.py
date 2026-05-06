from __future__ import annotations

from typing import Any, Mapping

from tbd_agents._utils import serialize_payload
from tbd_agents.types import Memory, MemoryCreate, MemoryScope, MemorySearchRequest, MemoryUpdate

from .base import BaseResource


class MemoriesResource(BaseResource):
    def create(self, payload: MemoryCreate | Mapping[str, Any]) -> Memory:
        return self._post("/memories", payload, model=Memory)

    def list(
        self,
        *,
        agent_id: str | None = None,
        scope: MemoryScope | str | None = None,
        tags: list[str] | None = None,
    ) -> list[Memory]:
        params: dict[str, Any] = {}
        if agent_id is not None:
            params["agent_id"] = agent_id
        if scope is not None:
            params["scope"] = scope
        if tags:
            params["tags"] = ",".join(tags)
        return self._get_list("/memories", params=params or None, model=Memory)

    def get(self, memory_id: str) -> Memory:
        return self._get(f"/memories/{memory_id}", model=Memory)

    def update(self, memory_id: str, payload: MemoryUpdate | Mapping[str, Any]) -> Memory:
        return self._put(f"/memories/{memory_id}", payload, model=Memory)

    def delete(self, memory_id: str) -> None:
        self._delete(f"/memories/{memory_id}")

    def search(self, payload: MemorySearchRequest | Mapping[str, Any]) -> list[Memory]:
        data = self._client.request("POST", "/memories/search", json=serialize_payload(payload))
        return [Memory.model_validate(item) for item in data]

    def get_stm(self, agent_id: str) -> list[Memory]:
        data = self._client.request("GET", f"/memories/stm/{agent_id}")
        return [Memory.model_validate(item) for item in data]
