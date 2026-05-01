from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import AllowedToolsUpdate, McpServer, McpServerCreate, McpServerUpdate, McpTestResult, McpTools

from .base import BaseResource


class McpsResource(BaseResource):
    def create(self, payload: McpServerCreate | Mapping[str, Any]) -> McpServer:
        return self._post("/mcps", payload, model=McpServer)

    def list(self) -> list[McpServer]:
        return self._get_list("/mcps", model=McpServer)

    def get(self, server_id: str) -> McpServer:
        return self._get(f"/mcps/{server_id}", model=McpServer)

    def update(self, server_id: str, payload: McpServerUpdate | Mapping[str, Any]) -> McpServer:
        return self._put(f"/mcps/{server_id}", payload, model=McpServer)

    def delete(self, server_id: str) -> None:
        self._delete(f"/mcps/{server_id}")

    def test(self, server_id: str) -> McpTestResult:
        return self._post(f"/mcps/{server_id}/test", model=McpTestResult)

    def list_tools(self, server_id: str) -> McpTools:
        return self._get(f"/mcps/{server_id}/tools", model=McpTools)

    def update_tools(
        self,
        server_id: str,
        allowed_tools: list[str] | AllowedToolsUpdate,
    ) -> AllowedToolsUpdate:
        payload = allowed_tools
        if isinstance(allowed_tools, list):
            payload = AllowedToolsUpdate(allowed_tools=allowed_tools)
        return self._put(f"/mcps/{server_id}/tools", payload, model=AllowedToolsUpdate)

