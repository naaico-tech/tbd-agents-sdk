from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import (
    ExportedKnowledgeSource,
    ImportResult,
    KnowledgeSource,
    KnowledgeSourceCreate,
    KnowledgeSourceExportBundle,
    KnowledgeSourceImportBundle,
    KnowledgeSourceTestResult,
    KnowledgeSourceUpdate,
)

from .base import BaseResource


class KnowledgeSourcesResource(BaseResource):
    def create(self, payload: KnowledgeSourceCreate | Mapping[str, Any]) -> KnowledgeSource:
        return self._post("/knowledge-sources", payload, model=KnowledgeSource)

    def list(self, *, tags: list[str] | None = None) -> list[KnowledgeSource]:
        params = {"tags": ",".join(tags)} if tags else None
        return self._get_list("/knowledge-sources", params=params, model=KnowledgeSource)

    def get(self, source_id: str) -> KnowledgeSource:
        return self._get(f"/knowledge-sources/{source_id}", model=KnowledgeSource)

    def update(
        self,
        source_id: str,
        payload: KnowledgeSourceUpdate | Mapping[str, Any],
    ) -> KnowledgeSource:
        return self._put(f"/knowledge-sources/{source_id}", payload, model=KnowledgeSource)

    def delete(self, source_id: str) -> None:
        self._delete(f"/knowledge-sources/{source_id}")

    def test(self, source_id: str) -> KnowledgeSourceTestResult:
        return self._post(f"/knowledge-sources/{source_id}/test", model=KnowledgeSourceTestResult)

    def export(self, source_id: str | None = None) -> KnowledgeSourceExportBundle:
        path = (
            "/knowledge-sources/export"
            if source_id is None
            else f"/knowledge-sources/{source_id}/export"
        )
        return self._get(path, model=KnowledgeSourceExportBundle)

    def import_(
        self,
        payload: KnowledgeSourceImportBundle | Mapping[str, Any],
    ) -> ImportResult:
        return self._post("/knowledge-sources/import", payload, model=ImportResult)

