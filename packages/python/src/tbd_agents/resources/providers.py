from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import Provider, ProviderCreate, ProviderUpdate

from .base import BaseResource


class ProvidersResource(BaseResource):
    def create(self, payload: ProviderCreate | Mapping[str, Any]) -> Provider:
        return self._post("/providers", payload, model=Provider)

    def list(self) -> list[Provider]:
        return self._get_list("/providers", model=Provider)

    def get(self, provider_id: str) -> Provider:
        return self._get(f"/providers/{provider_id}", model=Provider)

    def update(self, provider_id: str, payload: ProviderUpdate | Mapping[str, Any]) -> Provider:
        return self._put(f"/providers/{provider_id}", payload, model=Provider)

    def delete(self, provider_id: str) -> None:
        self._delete(f"/providers/{provider_id}")

