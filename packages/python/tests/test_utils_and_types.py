from __future__ import annotations

import httpx
import pytest
from pydantic import ValidationError

from tbd_agents._utils import (
    normalize_base_urls,
    parse_content_disposition_filename,
    serialize_payload,
)
from tbd_agents.exceptions import ApiError, TransportError
from tbd_agents.types import PromptRequest, SkillCreate


def test_normalize_base_urls_handles_api_suffix_and_empty_values() -> None:
    assert normalize_base_urls("https://example.com/") == (
        "https://example.com",
        "https://example.com/api",
    )
    assert normalize_base_urls("https://example.com/api") == (
        "https://example.com",
        "https://example.com/api",
    )

    with pytest.raises(ValueError, match="base_url must not be empty"):
        normalize_base_urls("/")


def test_serialize_payload_handles_none_models_and_mappings() -> None:
    model = SkillCreate(name="summarize", instructions="Summarize text", tags=["docs"])

    assert serialize_payload(None) is None
    assert serialize_payload(model) == {
        "name": "summarize",
        "description": "",
        "instructions": "Summarize text",
        "tags": ["docs"],
    }
    assert serialize_payload({"name": "plain"}) == {"name": "plain"}


@pytest.mark.parametrize(
    ("header", "expected"),
    [
        (None, None),
        ("attachment", None),
        ('attachment; filename="report.txt"', "report.txt"),
        ("attachment; filename=report.txt", "report.txt"),
    ],
)
def test_parse_content_disposition_filename(header: str | None, expected: str | None) -> None:
    assert parse_content_disposition_filename(header) == expected


def test_prompt_request_requires_prompt_or_request() -> None:
    with pytest.raises(ValidationError, match="either prompt or request must be provided"):
        PromptRequest()

    assert PromptRequest(prompt="hello").prompt == "hello"
    assert PromptRequest(request={"input": "hello"}).request == {"input": "hello"}


def test_exceptions_capture_attributes() -> None:
    cause = RuntimeError("network down")
    transport_error = TransportError("transport failed", cause=cause)
    response = httpx.Response(400, json={"detail": "bad request"})
    api_error = ApiError("bad request", status_code=400, response=response, body={"detail": "bad request"})

    assert transport_error.cause is cause
    assert api_error.status_code == 400
    assert api_error.response is response
    assert api_error.body == {"detail": "bad request"}
