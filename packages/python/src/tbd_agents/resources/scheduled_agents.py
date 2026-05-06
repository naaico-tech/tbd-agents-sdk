from __future__ import annotations

from typing import Any, Mapping

from tbd_agents._utils import serialize_payload
from tbd_agents.types import ScheduledAgent, ScheduledAgentCreate, ScheduledAgentUpdate

from .base import BaseResource


class ScheduledAgentsResource(BaseResource):
    def create(self, payload: ScheduledAgentCreate | Mapping[str, Any]) -> ScheduledAgent:
        return self._post("/scheduled-agents", payload, model=ScheduledAgent)

    def list(self) -> list[ScheduledAgent]:
        return self._get_list("/scheduled-agents", model=ScheduledAgent)

    def get(self, sa_id: str) -> ScheduledAgent:
        return self._get(f"/scheduled-agents/{sa_id}", model=ScheduledAgent)

    def update(self, sa_id: str, payload: ScheduledAgentUpdate | Mapping[str, Any]) -> ScheduledAgent:
        data = self._client.request("PATCH", f"/scheduled-agents/{sa_id}", json=serialize_payload(payload))
        return ScheduledAgent.model_validate(data)

    def enable(self, sa_id: str) -> ScheduledAgent:
        data = self._client.request("PATCH", f"/scheduled-agents/{sa_id}/enable")
        return ScheduledAgent.model_validate(data)

    def disable(self, sa_id: str) -> ScheduledAgent:
        data = self._client.request("PATCH", f"/scheduled-agents/{sa_id}/disable")
        return ScheduledAgent.model_validate(data)

    def delete(self, sa_id: str) -> None:
        self._delete(f"/scheduled-agents/{sa_id}")
