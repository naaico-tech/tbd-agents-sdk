from __future__ import annotations

import time
from collections.abc import Callable, Iterator
from typing import Any, Mapping

from tbd_agents._sse import iter_sse_messages
from tbd_agents.exceptions import TbdAgentsError
from tbd_agents.types import (
    DetailResponse,
    ImportResult,
    PromptRequest,
    PromptResponse,
    TaskExecution,
    TaskStatus,
    Workflow,
    WorkflowCreate,
    WorkflowExportBundle,
    WorkflowImportBundle,
    WorkflowStreamEvent,
    WorkflowUpdate,
)

from .base import BaseResource


class WorkflowsResource(BaseResource):
    TERMINAL_TASK_STATUSES = {
        TaskStatus.COMPLETED,
        TaskStatus.FAILED,
        TaskStatus.HALTED,
        TaskStatus.MAX_TURNS_REACHED,
    }

    def create(self, payload: WorkflowCreate | Mapping[str, Any]) -> Workflow:
        return self._post("/workflows", payload, model=Workflow)

    def list(self) -> list[Workflow]:
        return self._get_list("/workflows", model=Workflow)

    def get(self, workflow_id: str) -> Workflow:
        return self._get(f"/workflows/{workflow_id}", model=Workflow)

    def update(self, workflow_id: str, payload: WorkflowUpdate | Mapping[str, Any]) -> Workflow:
        return self._put(f"/workflows/{workflow_id}", payload, model=Workflow)

    def delete(self, workflow_id: str) -> None:
        self._delete(f"/workflows/{workflow_id}")

    def export(self, workflow_id: str | None = None) -> WorkflowExportBundle:
        path = "/workflows/export" if workflow_id is None else f"/workflows/{workflow_id}/export"
        return self._get(path, model=WorkflowExportBundle)

    def import_(self, payload: WorkflowImportBundle | Mapping[str, Any]) -> ImportResult:
        return self._post("/workflows/import", payload, model=ImportResult)

    def send_prompt(
        self,
        workflow_id: str,
        *,
        prompt: str | None = None,
        request: dict[str, Any] | None = None,
        reasoning_effort: str | None = None,
    ) -> PromptResponse:
        payload = PromptRequest(
            prompt=prompt,
            request=request,
            reasoning_effort=reasoning_effort,
        )
        return self._post(f"/workflows/{workflow_id}/prompt", payload, model=PromptResponse)

    def halt(self, workflow_id: str) -> DetailResponse:
        return self._post(f"/workflows/{workflow_id}/halt", model=DetailResponse)

    def install_skill(self, workflow_id: str, skill_id: str) -> Workflow:
        return self._post(f"/workflows/{workflow_id}/skills/{skill_id}", model=Workflow)

    def remove_skill(self, workflow_id: str, skill_id: str) -> Workflow:
        response = self._client.request("DELETE", f"/workflows/{workflow_id}/skills/{skill_id}")
        return Workflow.model_validate(response)

    def list_tasks(self, workflow_id: str) -> list[TaskExecution]:
        return [
            TaskExecution.model_validate(task)
            for task in self._client.request("GET", f"/tasks/workflow/{workflow_id}")
        ]

    def wait_for_task(
        self,
        task_id: str,
        *,
        interval: float = 1.0,
        timeout: float | None = 300.0,
        predicate: Callable[[TaskExecution], bool] | None = None,
    ) -> TaskExecution:
        started = time.monotonic()
        condition = predicate or (
            lambda task: task.status in self.TERMINAL_TASK_STATUSES
        )

        while True:
            task = self._client.tasks.get(task_id)
            if condition(task):
                return task
            if timeout is not None and time.monotonic() - started >= timeout:
                raise TimeoutError(f"timed out waiting for task {task_id}")
            time.sleep(interval)

    def wait_for_workflow(
        self,
        workflow_id: str,
        *,
        interval: float = 1.0,
        timeout: float | None = 300.0,
        predicate: Callable[[Workflow], bool] | None = None,
    ) -> Workflow:
        initial = self.get(workflow_id)
        started = time.monotonic()
        condition = predicate or (
            lambda workflow: workflow.updated_at != initial.updated_at
            or workflow.task_count != initial.task_count
        )

        while True:
            workflow = self.get(workflow_id)
            if condition(workflow):
                return workflow
            if timeout is not None and time.monotonic() - started >= timeout:
                raise TimeoutError(f"timed out waiting for workflow {workflow_id}")
            time.sleep(interval)

    def run_prompt(
        self,
        workflow_id: str,
        *,
        prompt: str | None = None,
        request: dict[str, Any] | None = None,
        reasoning_effort: str | None = None,
        interval: float = 1.0,
        timeout: float | None = 300.0,
    ) -> TaskExecution:
        before = self.list_tasks(workflow_id)
        known_ids = {task.id for task in before}
        self.send_prompt(
            workflow_id,
            prompt=prompt,
            request=request,
            reasoning_effort=reasoning_effort,
        )

        started = time.monotonic()
        while True:
            tasks = self.list_tasks(workflow_id)
            for task in tasks:
                if task.id not in known_ids:
                    return self.wait_for_task(task.id, interval=interval, timeout=timeout)
            if timeout is not None and time.monotonic() - started >= timeout:
                raise TimeoutError(f"timed out waiting for workflow {workflow_id} task creation")
            time.sleep(interval)

    def stream(
        self,
        workflow_id: str,
        *,
        last_event_id: str | int | None = None,
    ) -> Iterator[WorkflowStreamEvent]:
        headers: dict[str, str] = {}
        if last_event_id is not None:
            headers["Last-Event-ID"] = str(last_event_id)

        with self._client.stream("GET", f"/workflows/{workflow_id}/stream", headers=headers) as response:
            self._client.raise_for_status(response)
            for message in iter_sse_messages(response.iter_lines()):
                if not message.data:
                    continue
                yield WorkflowStreamEvent.model_validate_json(message.data)

