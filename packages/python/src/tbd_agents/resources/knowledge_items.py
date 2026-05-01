from __future__ import annotations

import json
from pathlib import Path
from typing import Any, BinaryIO, Mapping

from tbd_agents._utils import parse_content_disposition_filename
from tbd_agents.types import (
    DownloadedContent,
    KnowledgeItem,
    KnowledgeItemCreate,
    KnowledgeItemUpdate,
    KnowledgeQueryResponse,
)

from .base import BaseResource


class KnowledgeItemsResource(BaseResource):
    def create(self, payload: KnowledgeItemCreate | Mapping[str, Any]) -> KnowledgeItem:
        return self._post("/knowledge-items", payload, model=KnowledgeItem)

    def list(
        self,
        *,
        source_id: str | None = None,
        tags: list[str] | None = None,
        content_type: str | None = None,
    ) -> list[KnowledgeItem]:
        params: dict[str, Any] = {}
        if source_id is not None:
            params["source_id"] = source_id
        if tags:
            params["tags"] = ",".join(tags)
        if content_type is not None:
            params["content_type"] = content_type
        return self._get_list("/knowledge-items", params=params or None, model=KnowledgeItem)

    def get(self, item_id: str) -> KnowledgeItem:
        return self._get(f"/knowledge-items/{item_id}", model=KnowledgeItem)

    def update(self, item_id: str, payload: KnowledgeItemUpdate | Mapping[str, Any]) -> KnowledgeItem:
        return self._put(f"/knowledge-items/{item_id}", payload, model=KnowledgeItem)

    def delete(self, item_id: str) -> None:
        self._delete(f"/knowledge-items/{item_id}")

    def query(self, *, tags: list[str], limit: int = 10) -> KnowledgeQueryResponse:
        return self._post(
            "/knowledge-items/query",
            {"tags": tags, "limit": limit},
            model=KnowledgeQueryResponse,
        )

    def upload(
        self,
        *,
        source_id: str,
        file: bytes | BinaryIO | str | Path,
        filename: str | None = None,
        content_type: str | None = None,
        tags: list[str] | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> KnowledgeItem:
        close_after = False
        file_handle: BinaryIO | None = None
        file_name = filename

        if isinstance(file, (str, Path)):
            path = Path(file)
            file_handle = path.open("rb")
            close_after = True
            file_name = file_name or path.name
            file_payload: bytes | BinaryIO = file_handle
        elif hasattr(file, "read"):
            file_handle = file  # type: ignore[assignment]
            file_name = file_name or getattr(file, "name", "upload.bin")
            file_payload = file_handle
        else:
            file_payload = file
            file_name = file_name or "upload.bin"

        try:
            files = {
                "file": (
                    file_name,
                    file_payload,
                    content_type or "application/octet-stream",
                )
            }
            data = {
                "source_id": source_id,
                "tags": json.dumps(tags or []),
                "metadata": json.dumps(metadata or {}),
            }
            return self._post("/knowledge-items/upload", model=KnowledgeItem, files=files, data=data)
        finally:
            if close_after and file_handle is not None:
                file_handle.close()

    def download(self, item_id: str) -> DownloadedContent:
        response = self._client.raw_request("GET", f"/knowledge-items/{item_id}/content")
        self._client.raise_for_status(response)
        return DownloadedContent(
            content=response.content,
            content_type=response.headers.get("content-type"),
            filename=parse_content_disposition_filename(
                response.headers.get("content-disposition")
            ),
        )

