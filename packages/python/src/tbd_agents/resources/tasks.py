from __future__ import annotations

from tbd_agents.types import TaskExecution, TaskProgress, TaskExecutionSummary

from .base import BaseResource


class TasksResource(BaseResource):
    def list(self) -> list[TaskExecutionSummary]:
        return self._get_list("/tasks", model=TaskExecutionSummary)

    def get(self, task_id: str) -> TaskExecution:
        return self._get(f"/tasks/{task_id}", model=TaskExecution)

    def progress(self, task_id: str) -> TaskProgress:
        return self._get(f"/tasks/{task_id}/progress", model=TaskProgress)

    def list_for_workflow(self, workflow_id: str) -> list[TaskExecutionSummary]:
        return self._get_list(f"/tasks/workflow/{workflow_id}", model=TaskExecutionSummary)

