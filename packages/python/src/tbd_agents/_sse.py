from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, Iterator


@dataclass
class SSEMessage:
    data: str
    event: str | None = None
    event_id: str | None = None
    retry: int | None = None


def iter_sse_messages(lines: Iterable[str]) -> Iterator[SSEMessage]:
    data_lines: list[str] = []
    event_name: str | None = None
    event_id: str | None = None
    retry: int | None = None

    def flush() -> SSEMessage | None:
        nonlocal data_lines, event_name, event_id, retry
        if not data_lines and event_name is None and event_id is None and retry is None:
            return None
        message = SSEMessage(
            data="\n".join(data_lines),
            event=event_name,
            event_id=event_id,
            retry=retry,
        )
        data_lines = []
        event_name = None
        event_id = None
        retry = None
        return message

    for raw_line in lines:
        line = raw_line.rstrip("\r")
        if line == "":
            message = flush()
            if message is not None:
                yield message
            continue
        if line.startswith(":"):
            continue

        field, _, value = line.partition(":")
        if value.startswith(" "):
            value = value[1:]

        if field == "data":
            data_lines.append(value)
        elif field == "event":
            event_name = value
        elif field == "id":
            event_id = value
        elif field == "retry":
            try:
                retry = int(value)
            except ValueError:
                retry = None

    message = flush()
    if message is not None:
        yield message

