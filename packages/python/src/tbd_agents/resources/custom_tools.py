from __future__ import annotations

import json
from pathlib import Path
from typing import Any, BinaryIO, Mapping

from tbd_agents.types import (
    CustomTool,
    CustomToolCreate,
    CustomToolRunRequest,
    CustomToolRunResponse,
    CustomToolUpdate,
    CustomToolValidateRequest,
    CustomToolValidateResponse,
    EnvMappingResponse,
    EnvMappingUpdate,
)

from .base import BaseResource


class CustomToolsResource(BaseResource):
    def create(self, payload: CustomToolCreate | Mapping[str, Any]) -> CustomTool:
        return self._post("/custom-tools", payload, model=CustomTool)

    def list(self, *, tag: str | None = None) -> list[CustomTool]:
        params = {"tag": tag} if tag else None
        return self._get_list("/custom-tools", params=params, model=CustomTool)

    def get(self, tool_id: str) -> CustomTool:
        return self._get(f"/custom-tools/{tool_id}", model=CustomTool)

    def update(self, tool_id: str, payload: CustomToolUpdate | Mapping[str, Any]) -> CustomTool:
        return self._put(f"/custom-tools/{tool_id}", payload, model=CustomTool)

    def delete(self, tool_id: str) -> None:
        self._delete(f"/custom-tools/{tool_id}")

    def run(self, tool_id: str, payload: CustomToolRunRequest | Mapping[str, Any]) -> CustomToolRunResponse:
        return self._post(f"/custom-tools/{tool_id}/run", payload, model=CustomToolRunResponse)

    def validate(self, payload: CustomToolValidateRequest | Mapping[str, Any]) -> CustomToolValidateResponse:
        return self._post("/custom-tools/validate", payload, model=CustomToolValidateResponse)

    def upload(
        self,
        *,
        source_code: str | bytes | BinaryIO | Path,
        name: str,
        description: str = "",
        tags: list[str] | None = None,
    ) -> CustomTool:
        close_after = False
        file_handle: BinaryIO | None = None
        file_name = f"{name}.py"
        file_payload: bytes | BinaryIO

        if isinstance(source_code, (str, Path)):
            path = Path(source_code) if isinstance(source_code, Path) else None
            if path is not None and path.exists():
                file_handle = path.open("rb")
                close_after = True
                file_name = path.name
                file_payload = file_handle
            else:
                raw = source_code if isinstance(source_code, str) else source_code.decode()
                file_payload = raw.encode("utf-8") if isinstance(raw, str) else raw  # type: ignore[assignment]
        elif hasattr(source_code, "read"):
            file_handle = source_code  # type: ignore[assignment]
            file_payload = file_handle
        else:
            file_payload = source_code  # type: ignore[assignment]

        try:
            files = {"file": (file_name, file_payload, "text/plain")}
            data = {
                "name": name,
                "description": description,
                "tags": json.dumps(tags or []),
            }
            return self._post("/custom-tools/upload", model=CustomTool, files=files, data=data)
        finally:
            if close_after and file_handle is not None:
                file_handle.close()

    def get_env_mapping(self, tool_id: str) -> EnvMappingResponse:
        return self._get(f"/custom-tools/{tool_id}/env-mapping", model=EnvMappingResponse)

    def update_env_mapping(
        self, tool_id: str, payload: EnvMappingUpdate | Mapping[str, Any]
    ) -> EnvMappingResponse:
        return self._put(f"/custom-tools/{tool_id}/env-mapping", payload, model=EnvMappingResponse)
