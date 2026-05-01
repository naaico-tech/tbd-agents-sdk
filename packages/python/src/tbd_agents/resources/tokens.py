from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import Token, TokenCreate, TokenUpdate

from .base import BaseResource


class TokensResource(BaseResource):
    def create(self, payload: TokenCreate | Mapping[str, Any]) -> Token:
        return self._post("/tokens", payload, model=Token)

    def list(self) -> list[Token]:
        return self._get_list("/tokens", model=Token)

    def get(self, token_id: str) -> Token:
        return self._get(f"/tokens/{token_id}", model=Token)

    def update(self, token_id: str, payload: TokenUpdate | Mapping[str, Any]) -> Token:
        return self._put(f"/tokens/{token_id}", payload, model=Token)

    def delete(self, token_id: str) -> None:
        self._delete(f"/tokens/{token_id}")

