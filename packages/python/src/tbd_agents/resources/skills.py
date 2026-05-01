from __future__ import annotations

from typing import Any, Mapping

from tbd_agents.types import (
    ImportResult,
    Skill,
    SkillCreate,
    SkillExportBundle,
    SkillImportBundle,
    SkillUpdate,
)

from .base import BaseResource


class SkillsResource(BaseResource):
    def create(self, payload: SkillCreate | Mapping[str, Any]) -> Skill:
        return self._post("/skills", payload, model=Skill)

    def list(self) -> list[Skill]:
        return self._get_list("/skills", model=Skill)

    def get(self, skill_id: str) -> Skill:
        return self._get(f"/skills/{skill_id}", model=Skill)

    def update(self, skill_id: str, payload: SkillUpdate | Mapping[str, Any]) -> Skill:
        return self._put(f"/skills/{skill_id}", payload, model=Skill)

    def delete(self, skill_id: str) -> None:
        self._delete(f"/skills/{skill_id}")

    def export(self, skill_id: str | None = None) -> SkillExportBundle:
        path = "/skills/export" if skill_id is None else f"/skills/{skill_id}/export"
        return self._get(path, model=SkillExportBundle)

    def import_(self, payload: SkillImportBundle | Mapping[str, Any]) -> ImportResult:
        return self._post("/skills/import", payload, model=ImportResult)

