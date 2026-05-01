from __future__ import annotations

import httpx

from tbd_agents import TbdAgentsClient


def test_client_builds_api_and_health_urls() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if request.url.path == "/health":
            return httpx.Response(200, json={"status": "ok"})
        if request.url.path == "/api/agents":
            return httpx.Response(200, json=[])
        raise AssertionError(f"unexpected path {request.url.path}")

    transport = httpx.MockTransport(handler)

    with TbdAgentsClient(
        base_url="https://example.com",
        token="secret-token",
        default_headers={"X-Test": "1"},
        transport=transport,
    ) as client:
        assert client.health.get().status == "ok"
        assert client.agents.list() == []

    assert [request.url.path for request in seen] == ["/health", "/api/agents"]
    for request in seen:
        assert request.headers["authorization"] == "Bearer secret-token"
        assert request.headers["x-test"] == "1"


def test_client_omits_authorization_header_without_token() -> None:
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        assert "authorization" not in request.headers
        return httpx.Response(200, json={"status": "ok"})

    with TbdAgentsClient(
        base_url="https://example.com",
        default_headers={"Authorization": "Bearer should-not-be-sent", "X-Test": "1"},
        transport=httpx.MockTransport(handler),
    ) as client:
        assert client.health.get().status == "ok"

    assert len(seen) == 1
    assert seen[0].headers["x-test"] == "1"


def test_client_omits_authorization_header_for_blank_token() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert "authorization" not in request.headers
        return httpx.Response(200, json=[])

    with TbdAgentsClient(
        base_url="https://example.com",
        token="   ",
        transport=httpx.MockTransport(handler),
    ) as client:
        assert client.agents.list() == []


def test_client_accepts_api_base_url() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/models"
        return httpx.Response(200, json=[{"id": "gpt-5"}])

    with TbdAgentsClient(
        base_url="https://example.com/api",
        token="token",
        transport=httpx.MockTransport(handler),
    ) as client:
        result = client.models.list()

    assert result == [{"id": "gpt-5"}]
