from __future__ import annotations

from tbd_agents.types import HealthStatus

from .base import BaseResource


class HealthResource(BaseResource):
    def get(self) -> HealthStatus:
        data = self._client.request("GET", "/health", api=False)
        return self._parse_model(data, HealthStatus)

