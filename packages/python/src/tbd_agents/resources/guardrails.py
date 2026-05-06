from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import Guardrail, GuardrailCreate, GuardrailUpdate

from .base import BaseResource


class GuardrailsResource(BaseResource):
    def create(self, payload: GuardrailCreate | Mapping[str, Any]) -> Guardrail:
        return self._post("/guardrails", payload, model=Guardrail)

    def list(self, *, tag: str | None = None) -> list[Guardrail]:
        params = {"tag": tag} if tag else None
        return self._get_list("/guardrails", params=params, model=Guardrail)

    def get(self, guardrail_id: str) -> Guardrail:
        return self._get(f"/guardrails/{guardrail_id}", model=Guardrail)

    def update(self, guardrail_id: str, payload: GuardrailUpdate | Mapping[str, Any]) -> Guardrail:
        return self._put(f"/guardrails/{guardrail_id}", payload, model=Guardrail)

    def delete(self, guardrail_id: str) -> None:
        self._delete(f"/guardrails/{guardrail_id}")
