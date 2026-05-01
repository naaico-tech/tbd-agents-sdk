from __future__ import annotations

import re
from typing import Any, Mapping

from pydantic import BaseModel


def normalize_base_urls(base_url: str) -> tuple[str, str]:
    value = base_url.rstrip("/")
    if not value:
        raise ValueError("base_url must not be empty")
    if value.endswith("/api"):
        return value[:-4], value
    return value, f"{value}/api"


def serialize_payload(payload: BaseModel | Mapping[str, Any] | None) -> dict[str, Any] | None:
    if payload is None:
        return None
    if isinstance(payload, BaseModel):
        return payload.model_dump(mode="json", exclude_none=True)
    return dict(payload)


_CONTENT_DISPOSITION_FILENAME_RE = re.compile(r'filename="?(?P<filename>[^";]+)"?')


def parse_content_disposition_filename(header: str | None) -> str | None:
    if not header:
        return None
    match = _CONTENT_DISPOSITION_FILENAME_RE.search(header)
    if not match:
        return None
    return match.group("filename")

