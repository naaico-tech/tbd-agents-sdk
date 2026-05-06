from __future__ import annotations

import io
from contextlib import contextmanager
from pathlib import Path
from typing import Any

import httpx
import pytest

from tbd_agents.resources.base import BaseResource
from tbd_agents.resources.health import HealthResource
from tbd_agents.resources.knowledge_items import KnowledgeItemsResource
from tbd_agents.resources.knowledge_sources import KnowledgeSourcesResource
from tbd_agents.resources.mcps import McpsResource
from tbd_agents.resources.models import ModelsResource
from tbd_agents.resources.tasks import TasksResource
from tbd_agents.resources.workflows import WorkflowsResource
from tbd_agents.types import AllowedToolsUpdate, DetailResponse, TaskExecution, TaskStatus, Workflow

ISO_TIME = "2025-05-01T00:00:00Z"
LATER_TIME = "2025-05-01T00:00:01Z"


def workflow_payload(**overrides: Any) -> dict[str, Any]:
    payload = {
        "id": "wf_1",
        "title": "Workflow",
        "agent_id": "ag_1",
        "github_user": "octocat",
        "model": "gpt-5",
        "max_turns": 5,
        "current_turn": 1,
        "status": "active",
        "output_format": "json",
        "task_count": 0,
        "created_at": ISO_TIME,
        "updated_at": ISO_TIME,
    }
    payload.update(overrides)
    return payload


def task_payload(**overrides: Any) -> dict[str, Any]:
    payload = {
        "id": "task_1",
        "workflow_id": "wf_1",
        "prompt": "Hello",
        "status": "pending",
        "created_at": ISO_TIME,
    }
    payload.update(overrides)
    return payload


def knowledge_item_payload(**overrides: Any) -> dict[str, Any]:
    payload = {
        "id": "ki_1",
        "source_id": "ks_1",
        "name": "Doc",
        "content_type": "text",
        "tags": [],
        "metadata": {},
        "created_at": ISO_TIME,
        "updated_at": ISO_TIME,
    }
    payload.update(overrides)
    return payload


def knowledge_source_payload(**overrides: Any) -> dict[str, Any]:
    payload = {
        "id": "ks_1",
        "name": "Knowledge",
        "description": "Docs",
        "source_type": "vector_db",
        "connection_config": {},
        "tags": [],
        "status": "connected",
        "created_at": ISO_TIME,
        "updated_at": ISO_TIME,
    }
    payload.update(overrides)
    return payload


class StubClient:
    def __init__(self, *, responses: list[Any] | None = None, raw_response: httpx.Response | None = None) -> None:
        self.responses = list(responses or [])
        self.raw_response = raw_response
        self.request_calls: list[tuple[str, str, dict[str, Any]]] = []
        self.raw_calls: list[tuple[str, str, dict[str, Any]]] = []
        self.raise_for_status_calls: list[httpx.Response] = []

    def request(self, method: str, path: str, **kwargs: Any) -> Any:
        self.request_calls.append((method, path, kwargs))
        if not self.responses:
            return None
        response = self.responses.pop(0)
        if isinstance(response, Exception):
            raise response
        return response

    def raw_request(self, method: str, path: str, **kwargs: Any) -> httpx.Response:
        self.raw_calls.append((method, path, kwargs))
        if self.raw_response is None:
            raise AssertionError("missing raw response")
        return self.raw_response

    def raise_for_status(self, response: httpx.Response) -> None:
        self.raise_for_status_calls.append(response)


def test_base_resource_helpers_parse_and_send_payloads() -> None:
    client = StubClient(
        responses=[
            {"detail": "ok"},
            [{"detail": "ok"}],
            {"detail": "created"},
            {"detail": "updated"},
            {"detail": "raw"},
            None,
        ]
    )
    resource = BaseResource(client)  # type: ignore[arg-type]

    assert resource._get("/detail", model=DetailResponse).detail == "ok"
    assert resource._get_list("/details", model=DetailResponse)[0].detail == "ok"
    assert resource._post("/detail", {"detail": "created"}, model=DetailResponse).detail == "created"
    assert resource._put("/detail", {"detail": "updated"}, model=DetailResponse).detail == "updated"
    assert resource._post("/raw", {"detail": None}) == {"detail": "raw"}
    resource._delete("/detail")

    assert client.request_calls[0] == ("GET", "/detail", {"params": None})
    assert client.request_calls[1] == ("GET", "/details", {"params": None})
    assert client.request_calls[2][0:2] == ("POST", "/detail")
    assert client.request_calls[3][0:2] == ("PUT", "/detail")
    assert client.request_calls[-1] == ("DELETE", "/detail", {})


def test_health_and_models_resources_use_expected_request_shapes() -> None:
    client = StubClient(responses=[{"status": "ok"}, [{"id": "gpt-5"}], [{"id": "gpt-4"}]])

    assert HealthResource(client).get().status == "ok"  # type: ignore[arg-type]
    assert ModelsResource(client).list(provider_id="provider_1") == [{"id": "gpt-5"}]  # type: ignore[arg-type]
    assert ModelsResource(client).list() == [{"id": "gpt-4"}]  # type: ignore[arg-type]

    assert client.request_calls[0] == ("GET", "/health", {"api": False})
    assert client.request_calls[1] == ("GET", "/models", {"params": {"provider_id": "provider_1"}})
    assert client.request_calls[2] == ("GET", "/models", {"params": None})


def test_tasks_resource_parses_task_models() -> None:
    client = StubClient(
        responses=[
            [task_payload(status="running")],
            task_payload(status="completed"),
            {"todos": [{"id": 1, "title": "coverage", "status": "completed"}], "percent_complete": 100.0},
            [task_payload(status="failed")],
        ]
    )
    resource = TasksResource(client)  # type: ignore[arg-type]

    assert resource.list()[0].status == "running"
    assert resource.get("task_1").status == "completed"
    assert resource.progress("task_1").percent_complete == 100.0
    assert resource.list_for_workflow("wf_1")[0].status == "failed"


def test_knowledge_sources_and_mcps_cover_filtering_and_payload_coercion() -> None:
    client = StubClient(
        responses=[
            [knowledge_source_payload()],
            [knowledge_source_payload(tags=["sdk"])],
            {"version": "1.0", "exported_at": ISO_TIME, "resource_type": "knowledge_source", "items": []},
            {"version": "1.0", "exported_at": ISO_TIME, "resource_type": "knowledge_source", "items": []},
            {"success": True, "tools": [{"name": "echo"}]},
            {"tools": [{"name": "echo"}]},
            {"allowed_tools": ["echo"]},
            {"allowed_tools": ["echo", "cat"]},
        ]
    )

    knowledge_sources = KnowledgeSourcesResource(client)  # type: ignore[arg-type]
    mcps = McpsResource(client)  # type: ignore[arg-type]

    assert knowledge_sources.list()[0].id == "ks_1"
    assert knowledge_sources.list(tags=["sdk"])[0].tags == ["sdk"]
    assert knowledge_sources.export().resource_type == "knowledge_source"
    assert knowledge_sources.export("ks_1").resource_type == "knowledge_source"
    assert mcps.test("mcp_1").success is True
    assert mcps.list_tools("mcp_1").tools == [{"name": "echo"}]
    assert mcps.update_tools("mcp_1", ["echo"]) == AllowedToolsUpdate(allowed_tools=["echo"])
    assert mcps.update_tools("mcp_1", AllowedToolsUpdate(allowed_tools=["echo", "cat"])).allowed_tools == ["echo", "cat"]

    assert client.request_calls[1] == ("GET", "/knowledge-sources", {"params": {"tags": "sdk"}})
    assert client.request_calls[6][2]["json"] == {"allowed_tools": ["echo"]}
    assert client.request_calls[7][2]["json"] == {"allowed_tools": ["echo", "cat"]}


def test_knowledge_items_upload_list_query_and_download(tmp_path: Path) -> None:
    upload_path = tmp_path / "guide.txt"
    upload_path.write_text("guide")
    file_like = io.BytesIO(b"binary-data")
    file_like.name = "manual.bin"  # type: ignore[attr-defined]

    raw_response = httpx.Response(
        200,
        content=b"payload",
        headers={
            "content-type": "text/plain",
            "content-disposition": 'attachment; filename="guide.txt"',
        },
    )
    client = StubClient(
        responses=[
            [knowledge_item_payload()],
            [knowledge_item_payload(tags=["sdk"], content_type="file")],
            {"items": [knowledge_item_payload(name="query result")]},
            knowledge_item_payload(name="from path"),
            knowledge_item_payload(name="from file-like"),
            knowledge_item_payload(name="from bytes"),
        ],
        raw_response=raw_response,
    )
    resource = KnowledgeItemsResource(client)  # type: ignore[arg-type]

    assert resource.list()[0].name == "Doc"
    assert resource.list(source_id="ks_1", tags=["sdk"], content_type="file")[0].tags == ["sdk"]
    assert resource.query(tags=["sdk"], limit=2).items[0].name == "query result"

    uploaded_from_path = resource.upload(
        source_id="ks_1",
        file=upload_path,
        tags=["sdk"],
        metadata={"kind": "path"},
    )
    uploaded_from_file_like = resource.upload(source_id="ks_1", file=file_like)
    uploaded_from_bytes = resource.upload(source_id="ks_1", file=b"abc", filename=None)
    downloaded = resource.download("ki_1")

    assert uploaded_from_path.name == "from path"
    assert uploaded_from_file_like.name == "from file-like"
    assert uploaded_from_bytes.name == "from bytes"
    assert downloaded.content == b"payload"
    assert downloaded.content_type == "text/plain"
    assert downloaded.filename == "guide.txt"

    path_upload = client.request_calls[3][2]
    assert path_upload["data"] == {
        "source_id": "ks_1",
        "tags": '["sdk"]',
        "metadata": '{"kind": "path"}',
    }
    assert path_upload["files"]["file"][0] == "guide.txt"
    assert path_upload["files"]["file"][1].closed is True
    assert client.request_calls[4][2]["files"]["file"][0] == "manual.bin"
    assert client.request_calls[5][2]["files"]["file"][0] == "upload.bin"


def test_workflows_resource_waiters_and_streaming(monkeypatch: pytest.MonkeyPatch) -> None:
    class FakeTasks:
        def __init__(self) -> None:
            self.calls = 0

        def get(self, task_id: str) -> TaskExecution:
            self.calls += 1
            status = TaskStatus.PENDING if self.calls == 1 else TaskStatus.COMPLETED
            return TaskExecution.model_validate(task_payload(id=task_id, status=status))

    class WorkflowClient(StubClient):
        def __init__(self) -> None:
            super().__init__(
                responses=[
                    workflow_payload(),
                    workflow_payload(),
                    workflow_payload(updated_at=LATER_TIME, task_count=1),
                ]
            )
            self.tasks = FakeTasks()

        @contextmanager
        def stream(self, method: str, path: str, **kwargs: Any):
            self.request_calls.append((method, path, kwargs))
            response = httpx.Response(
                200,
                headers={"content-type": "text/event-stream"},
                content=(
                    b"id: 1\n"
                    b"data: \n\n"
                    b"id: 2\n"
                    b"data: {\"id\":2,\"type\":\"status\",\"data\":{\"status\":\"done\"}}\n\n"
                ),
            )
            yield response

    monotonic_values = iter([0.0, 0.1, 0.2, 0.3, 0.4])
    monkeypatch.setattr("tbd_agents.resources.workflows.time.monotonic", lambda: next(monotonic_values))
    monkeypatch.setattr("tbd_agents.resources.workflows.time.sleep", lambda interval: None)

    client = WorkflowClient()
    resource = WorkflowsResource(client)  # type: ignore[arg-type]

    waited_task = resource.wait_for_task("task_1", interval=0, timeout=1)
    waited_workflow = resource.wait_for_workflow("wf_1", interval=0, timeout=1)
    events = list(resource.stream("wf_1"))

    assert waited_task.status == TaskStatus.COMPLETED
    assert waited_workflow.task_count == 1
    assert [event.id for event in events] == [2]


def test_workflows_resource_run_prompt_and_timeout(monkeypatch: pytest.MonkeyPatch) -> None:
    client = StubClient()
    resource = WorkflowsResource(client)  # type: ignore[arg-type]

    seen_prompt_calls: list[tuple[str, str | None, dict[str, Any] | None, str | None]] = []
    task_lists = iter(
        [
            [TaskExecution.model_validate(task_payload(id="existing"))],
            [TaskExecution.model_validate(task_payload(id="existing")), TaskExecution.model_validate(task_payload(id="new-task"))],
        ]
    )

    monkeypatch.setattr(resource, "list_tasks", lambda workflow_id: next(task_lists))
    monkeypatch.setattr(
        resource,
        "send_prompt",
        lambda workflow_id, prompt=None, request=None, reasoning_effort=None: seen_prompt_calls.append(
            (workflow_id, prompt, request, reasoning_effort)
        ),
    )
    monkeypatch.setattr(
        resource,
        "wait_for_task",
        lambda task_id, interval, timeout: TaskExecution.model_validate(task_payload(id=task_id, status="completed")),
    )

    result = resource.run_prompt(
        "wf_1",
        prompt="Ship it",
        request={"temperature": 0},
        reasoning_effort="high",
        interval=0,
        timeout=1,
    )

    assert result.id == "new-task"
    assert seen_prompt_calls == [("wf_1", "Ship it", {"temperature": 0}, "high")]

    monotonic_values = iter([0.0, 1.0])
    monkeypatch.setattr("tbd_agents.resources.workflows.time.monotonic", lambda: next(monotonic_values))
    monkeypatch.setattr("tbd_agents.resources.workflows.time.sleep", lambda interval: None)
    monkeypatch.setattr(resource, "list_tasks", lambda workflow_id: [TaskExecution.model_validate(task_payload(id="existing"))])
    monkeypatch.setattr(resource, "send_prompt", lambda *args, **kwargs: None)

    with pytest.raises(TimeoutError, match="timed out waiting for workflow wf_1 task creation"):
        resource.run_prompt("wf_1", prompt="still waiting", interval=0, timeout=0.5)
