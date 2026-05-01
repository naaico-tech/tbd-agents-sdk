from __future__ import annotations

from contextlib import contextmanager
from typing import Any, Iterator, Mapping

import httpx

from tbd_agents._utils import normalize_base_urls
from tbd_agents.exceptions import ApiError, TransportError
from tbd_agents.resources import (
    AgentsResource,
    HealthResource,
    KnowledgeItemsResource,
    KnowledgeSourcesResource,
    McpsResource,
    ModelsResource,
    ProvidersResource,
    SkillsResource,
    TasksResource,
    TokensResource,
    WorkflowsResource,
)

USER_AGENT = "tbd-agents-python/0.1.0"


class TbdAgentsClient:
    def __init__(
        self,
        *,
        base_url: str,
        token: str,
        timeout: float | httpx.Timeout = 30.0,
        default_headers: Mapping[str, str] | None = None,
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        if not token or not token.strip():
            raise ValueError("token must be provided explicitly")

        self.base_url, self.api_base_url = normalize_base_urls(base_url)
        headers = {
            "Accept": "application/json",
            "Authorization": f"Bearer {token}",
            "User-Agent": USER_AGENT,
        }
        if default_headers:
            headers.update(default_headers)

        self._client = httpx.Client(
            timeout=timeout,
            headers=headers,
            transport=transport,
        )

        self.health = HealthResource(self)
        self.agents = AgentsResource(self)
        self.skills = SkillsResource(self)
        self.mcps = McpsResource(self)
        self.knowledge_sources = KnowledgeSourcesResource(self)
        self.knowledge_items = KnowledgeItemsResource(self)
        self.workflows = WorkflowsResource(self)
        self.tasks = TasksResource(self)
        self.providers = ProvidersResource(self)
        self.tokens = TokensResource(self)
        self.models = ModelsResource(self)

    def __enter__(self) -> "TbdAgentsClient":
        return self

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> None:
        self.close()

    def close(self) -> None:
        self._client.close()

    def _build_url(self, path: str, *, api: bool) -> str:
        if path.startswith(("http://", "https://")):
            return path
        base = self.api_base_url if api else self.base_url
        return f"{base.rstrip('/')}/{path.lstrip('/')}"

    def raise_for_status(self, response: httpx.Response) -> None:
        if response.status_code < 400:
            return

        body: Any | None = None
        message = response.reason_phrase
        try:
            body = response.json()
            if isinstance(body, dict) and "detail" in body:
                message = str(body["detail"])
            else:
                message = str(body)
        except ValueError:
            body = response.text
            if response.text:
                message = response.text

        raise ApiError(
            message,
            status_code=response.status_code,
            response=response,
            body=body,
        )

    def raw_request(
        self,
        method: str,
        path: str,
        *,
        api: bool = True,
        **kwargs: Any,
    ) -> httpx.Response:
        try:
            return self._client.request(method, self._build_url(path, api=api), **kwargs)
        except httpx.HTTPError as exc:
            raise TransportError(str(exc), cause=exc) from exc

    def request(
        self,
        method: str,
        path: str,
        *,
        api: bool = True,
        **kwargs: Any,
    ) -> Any:
        response = self.raw_request(method, path, api=api, **kwargs)
        self.raise_for_status(response)

        if response.status_code == 204 or not response.content:
            return None

        content_type = response.headers.get("content-type", "")
        if "application/json" in content_type:
            return response.json()

        return response.text

    @contextmanager
    def stream(
        self,
        method: str,
        path: str,
        *,
        api: bool = True,
        **kwargs: Any,
    ) -> Iterator[httpx.Response]:
        try:
            with self._client.stream(method, self._build_url(path, api=api), **kwargs) as response:
                yield response
        except httpx.HTTPError as exc:
            raise TransportError(str(exc), cause=exc) from exc

