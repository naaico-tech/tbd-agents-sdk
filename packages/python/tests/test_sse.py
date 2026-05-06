from __future__ import annotations

import httpx

from tbd_agents import TbdAgentsClient
from tbd_agents._sse import iter_sse_messages


def test_iter_sse_messages_handles_comments_and_multiline_data() -> None:
    lines = [
        ": keepalive",
        "id: 1",
        "data: {\"id\":1,",
        "data: \"type\":\"status\"}",
        "",
    ]

    messages = list(iter_sse_messages(lines))

    assert len(messages) == 1
    assert messages[0].event_id == "1"
    assert messages[0].data == "{\"id\":1,\n\"type\":\"status\"}"


def test_workflow_stream_parses_json_events() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/workflows/wf_123/stream"
        assert request.headers["last-event-id"] == "7"
        content = (
            b": keepalive\n\n"
            b"id: 8\n"
            b"data: {\"id\":8,\"type\":\"status\",\"data\":{\"status\":\"running\"},\"timestamp\":\"2025-05-01T00:00:00Z\"}\n\n"
            b"id: 9\n"
            b"data: {\"id\":9,\"type\":\"message\",\"data\":{\"content\":\"done\"},\"timestamp\":\"2025-05-01T00:00:01Z\"}\n\n"
        )
        return httpx.Response(
            200,
            headers={"content-type": "text/event-stream"},
            content=content,
        )

    with TbdAgentsClient(
        base_url="https://example.com",
        token="token",
        transport=httpx.MockTransport(handler),
    ) as client:
        events = list(client.workflows.stream("wf_123", last_event_id=7))

    assert [event.id for event in events] == [8, 9]
    assert events[0].type == "status"
    assert events[0].data == {"status": "running"}
    assert events[1].type == "message"
    assert events[1].data == {"content": "done"}


def test_iter_sse_messages_parses_event_retry_and_trailing_flush() -> None:
    lines = [
        "event: update",
        "id: 2",
        "retry: not-a-number",
        "data: first",
        "data: second",
    ]

    messages = list(iter_sse_messages(lines))

    assert len(messages) == 1
    assert messages[0].event == "update"
    assert messages[0].event_id == "2"
    assert messages[0].retry is None
    assert messages[0].data == "first\nsecond"
