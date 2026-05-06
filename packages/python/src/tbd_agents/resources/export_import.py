from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import BundleImportResult, FullExportBundle

from .base import BaseResource


class ExportImportResource(BaseResource):
    def export_all(self) -> FullExportBundle:
        return self._get("/export", model=FullExportBundle)

    def import_all(self, payload: FullExportBundle | Mapping[str, Any]) -> BundleImportResult:
        return self._post("/import", payload, model=BundleImportResult)
