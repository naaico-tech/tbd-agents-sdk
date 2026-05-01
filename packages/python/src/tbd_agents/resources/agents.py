from __future__ import annotations

from typing import Mapping, Any

from tbd_agents.types import (
    Agent,
    AgentCreate,
    AgentExportBundle,
    AgentImportBundle,
    AgentUpdate,
    ImportResult,
)

from .base import BaseResource


class AgentsResource(BaseResource):
    def create(self, payload: AgentCreate | Mapping[str, Any]) -> Agent:
        return self._post("/agents", payload, model=Agent)

    def list(self) -> list[Agent]:
        return self._get_list("/agents", model=Agent)

    def get(self, agent_id: str) -> Agent:
        return self._get(f"/agents/{agent_id}", model=Agent)

    def update(self, agent_id: str, payload: AgentUpdate | Mapping[str, Any]) -> Agent:
        return self._put(f"/agents/{agent_id}", payload, model=Agent)

    def delete(self, agent_id: str) -> None:
        self._delete(f"/agents/{agent_id}")

    def export(self, agent_id: str | None = None) -> AgentExportBundle:
        path = "/agents/export" if agent_id is None else f"/agents/{agent_id}/export"
        return self._get(path, model=AgentExportBundle)

    def import_(self, payload: AgentImportBundle | Mapping[str, Any]) -> ImportResult:
        return self._post("/agents/import", payload, model=ImportResult)

