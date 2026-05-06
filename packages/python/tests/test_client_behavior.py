from __future__ import annotations

from contextlib import contextmanager

import httpx
import pytest

from tbd_agents import TbdAgentsClient
from tbd_agents.exceptions import ApiError, TransportError


def test_client_build_url_preserves_absolute_urls() -> None:
    with TbdAgentsClient(base_url="https://example.com", transport=httpx.MockTransport(lambda request: httpx.Response(200))) as client:
        assert client._build_url("https://other.example.com/health", api=False) == "https://other.example.com/health"


def test_raise_for_status_prefers_json_detail_and_falls_back_to_text() -> None:
    with TbdAgentsClient(base_url="https://example.com", transport=httpx.MockTransport(lambda request: httpx.Response(200))) as client:
        detail_response = httpx.Response(422, json={"detail": "invalid payload"})
        with pytest.raises(ApiError, match="invalid payload") as detail_error:
            client.raise_for_status(detail_response)
        assert detail_error.value.body == {"detail": "invalid payload"}

        body_response = httpx.Response(500, json=["broken"])
        with pytest.raises(ApiError, match=r"\['broken'\]") as body_error:
            client.raise_for_status(body_response)
        assert body_error.value.body == ["broken"]

        text_response = httpx.Response(502, text="gateway failed")
        with pytest.raises(ApiError, match="gateway failed") as text_error:
            client.raise_for_status(text_response)
        assert text_error.value.body == "gateway failed"


def test_request_returns_none_for_empty_responses_and_text_for_non_json() -> None:
    calls: list[str] = []

    def handler(request: httpx.Request) -> httpx.Response:
        calls.append(request.url.path)
        if request.url.path == "/api/empty":
            return httpx.Response(204)
        if request.url.path == "/api/no-content":
            return httpx.Response(200, content=b"")
        if request.url.path == "/api/text":
            return httpx.Response(200, text="plain text", headers={"content-type": "text/plain"})
        raise AssertionError(f"unexpected path {request.url.path}")

    with TbdAgentsClient(
        base_url="https://example.com",
        transport=httpx.MockTransport(handler),
    ) as client:
        assert client.request("GET", "/empty") is None
        assert client.request("GET", "/no-content") is None
        assert client.request("GET", "/text") == "plain text"

    assert calls == ["/api/empty", "/api/no-content", "/api/text"]


def test_raw_request_wraps_http_errors() -> None:
    with TbdAgentsClient(base_url="https://example.com", transport=httpx.MockTransport(lambda request: httpx.Response(200))) as client:
        request = httpx.Request("GET", "https://example.com/api/fail")

        def boom(method: str, url: str, **kwargs: object) -> httpx.Response:
            raise httpx.ReadTimeout("timed out", request=request)

        client._client.request = boom  # type: ignore[assignment]

        with pytest.raises(TransportError, match="timed out") as error:
            client.raw_request("GET", "/fail")

    assert isinstance(error.value.cause, httpx.ReadTimeout)


def test_stream_wraps_http_errors() -> None:
    with TbdAgentsClient(base_url="https://example.com", transport=httpx.MockTransport(lambda request: httpx.Response(200))) as client:
        request = httpx.Request("GET", "https://example.com/api/fail")

        @contextmanager
        def broken_stream(method: str, url: str, **kwargs: object):  # type: ignore[override]
            raise httpx.ReadError("stream failed", request=request)
            yield

        client._client.stream = broken_stream  # type: ignore[assignment]

        with pytest.raises(TransportError, match="stream failed") as error:
            with client.stream("GET", "/fail"):
                pass

    assert isinstance(error.value.cause, httpx.ReadError)
