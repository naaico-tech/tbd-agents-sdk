from __future__ import annotations

from typing import Any, Mapping, TypeVar

from pydantic import BaseModel

from tbd_agents._utils import serialize_payload

ModelT = TypeVar("ModelT", bound=BaseModel)


class BaseResource:
    def __init__(self, client: "TbdAgentsClient") -> None:
        self._client = client

    def _parse_model(self, data: Any, model: type[ModelT]) -> ModelT:
        return model.model_validate(data)

    def _parse_list(self, data: Any, model: type[ModelT]) -> list[ModelT]:
        return [model.model_validate(item) for item in data]

    def _get(
        self,
        path: str,
        *,
        params: Mapping[str, Any] | None = None,
        model: type[ModelT] | None = None,
    ) -> Any:
        data = self._client.request("GET", path, params=params)
        if model is None:
            return data
        return self._parse_model(data, model)

    def _get_list(
        self,
        path: str,
        *,
        params: Mapping[str, Any] | None = None,
        model: type[ModelT],
    ) -> list[ModelT]:
        data = self._client.request("GET", path, params=params)
        return self._parse_list(data, model)

    def _post(
        self,
        path: str,
        payload: BaseModel | Mapping[str, Any] | None = None,
        *,
        model: type[ModelT] | None = None,
        files: Any = None,
        data: Mapping[str, Any] | None = None,
    ) -> Any:
        response = self._client.request(
            "POST",
            path,
            json=serialize_payload(payload),
            files=files,
            data=data,
        )
        if model is None:
            return response
        return self._parse_model(response, model)

    def _put(
        self,
        path: str,
        payload: BaseModel | Mapping[str, Any] | None = None,
        *,
        model: type[ModelT] | None = None,
    ) -> Any:
        response = self._client.request("PUT", path, json=serialize_payload(payload))
        if model is None:
            return response
        return self._parse_model(response, model)

    def _delete(self, path: str) -> None:
        self._client.request("DELETE", path)


from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tbd_agents.client import TbdAgentsClient

