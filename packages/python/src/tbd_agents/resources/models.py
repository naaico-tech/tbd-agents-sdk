from __future__ import annotations

from typing import Any

from .base import BaseResource


class ModelsResource(BaseResource):
    def list(self, *, provider_id: str | None = None) -> list[dict[str, Any]]:
        params = {"provider_id": provider_id} if provider_id else None
        return self._client.request("GET", "/models", params=params)

