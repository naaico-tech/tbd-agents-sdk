## 0.1.0

- Initial release.
- `TbdAgentsClient` with configurable HTTP client, token auth, timeout, and default headers.
- Resource helpers for health, agents, skills, mcps, knowledge_sources, knowledge_items,
  workflows, tasks, providers, tokens, and models.
- SSE streaming for `/api/workflows/{id}/stream`.
- Multipart upload and binary download for knowledge items.
- Raw request escape hatch via `TbdAgentsClient.rawRequest()`.
