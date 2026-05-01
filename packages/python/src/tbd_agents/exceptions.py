from __future__ import annotations

from typing import Any

import httpx


class TbdAgentsError(Exception):
    """Base SDK exception."""


class TransportError(TbdAgentsError):
    """Raised when the underlying HTTP transport fails."""

    def __init__(self, message: str, *, cause: Exception | None = None) -> None:
        super().__init__(message)
        self.cause = cause


class ApiError(TbdAgentsError):
    """Raised for non-successful API responses."""

    def __init__(
        self,
        message: str,
        *,
        status_code: int,
        response: httpx.Response,
        body: Any | None = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.response = response
        self.body = body

