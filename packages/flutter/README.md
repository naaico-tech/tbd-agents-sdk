# tbd_agents

Dart/Flutter SDK for the [TBD Agents](https://github.com/naaico-tech/tbd-agents-sdk) API.

## Features

- **`TbdAgentsClient`** — typed HTTP client with configurable base URL, bearer-token auth,
  timeout, custom default headers, and a pluggable `http.Client`.
- **Resource helpers** for every API surface:
  `health`, `agents`, `skills`, `mcps`, `knowledgeSources`, `knowledgeItems`,
  `workflows`, `tasks`, `providers`, `tokens`, `models`.
- **SSE streaming** via `WorkflowsResource.stream()` — yields
  `WorkflowStreamEvent` objects from `GET /api/workflows/{id}/stream`.
- **Multipart upload** (`KnowledgeItemsResource.upload`) and
  **binary download** (`KnowledgeItemsResource.download`).
- **Raw escape hatch** via `TbdAgentsClient.rawRequest()` for full control.
- Fully typed models (`Workflow`, `TaskExecution`, `KnowledgeItem`, …) with
  dynamic `extras` map for forward-compatibility.

## Installation

Published release artifacts for this package are attached to [GitHub Releases](https://github.com/naaico-tech/tbd-agents-sdk/releases).

Use a local path dependency during development:

```yaml
dependencies:
  tbd_agents:
    path: ../tbd-agents-sdk/packages/flutter
```

## Quick start

```dart
import 'package:tbd_agents/tbd_agents.dart';

Future<void> main() async {
  final client = TbdAgentsClient(
    baseUrl: 'https://my-server.example.com',
    timeoutMs: 30000,
  );

  // Health check (hits /health, outside /api).
  final health = await client.health.get();
  print(health.status); // 'ok'

  // List workflows.
  final workflows = await client.workflows.list();
  for (final wf in workflows) {
    print('${wf.id}: ${wf.status}');
  }

  // Create a workflow and send a prompt.
  final wf = await client.workflows.create(WorkflowCreate(agentId: 'ag_1'));
  await client.workflows.sendPrompt(wf.id, prompt: 'Hello!');

  // Stream SSE events.
  await for (final event in client.workflows.stream(wf.id)) {
    print('${event.type}: ${event.data}');
    if (event.type == 'status') break;
  }

  // Upload a knowledge item file.
  final item = await client.knowledgeItems.upload(
    sourceId: 'ks_1',
    bytes: [104, 101, 108, 108, 111], // b"hello"
    filename: 'hello.txt',
    tags: ['docs'],
    metadata: {'team': 'platform'},
  );
  print(item.id);

  // Download binary content.
  final downloaded = await client.knowledgeItems.download(item.id);
  print(downloaded.contentType);

  // Raw escape hatch.
  final raw = await client.rawRequest('GET', 'custom/endpoint');
  print(raw.statusCode);

  client.close();
}
```

If your deployment requires authentication, pass a token explicitly:

```dart
final authenticatedClient = TbdAgentsClient(
  baseUrl: 'https://agents.example.com',
  token: 'YOUR_TBD_AGENTS_TOKEN',
);
```

## Base URL handling

| `baseUrl` supplied | Effective base | API endpoints |
|---|---|---|
| `https://example.com` | `https://example.com` | `https://example.com/api/…` |
| `https://example.com/api` | `https://example.com` | `https://example.com/api/…` |
| `https://example.com/api/` | `https://example.com` | `https://example.com/api/…` |

`GET /health` is always routed to `{base}/health` (outside `/api`).

## Token / auth behaviour

- If `token` is `null` or blank, **no** `Authorization` header is sent.
- Whitespace in the token string is trimmed before use.
- Any `Authorization` key in `defaultHeaders` is silently ignored —
  use the `token` parameter instead.

## Pluggable HTTP client

Supply a custom `http.Client` for testing or advanced configuration:

```dart
import 'package:http/testing.dart';

final mockClient = MockClient((request) async {
  return Response(jsonEncode({'status': 'ok'}), 200,
      headers: {'content-type': 'application/json'});
});

final client = TbdAgentsClient(
  baseUrl: 'https://example.com',
  httpClient: mockClient,
);
```

## Resource reference

### `health`
| Method | Endpoint |
|---|---|
| `get()` | `GET /health` |

### `workflows`
| Method | Endpoint |
|---|---|
| `list()` | `GET /api/workflows` |
| `get(id)` | `GET /api/workflows/{id}` |
| `create(payload)` | `POST /api/workflows` |
| `update(id, payload)` | `PUT /api/workflows/{id}` |
| `delete(id)` | `DELETE /api/workflows/{id}` |
| `sendPrompt(id, prompt:…)` | `POST /api/workflows/{id}/prompt` |
| `halt(id)` | `POST /api/workflows/{id}/halt` |
| `installSkill(wfId, skillId)` | `POST /api/workflows/{wfId}/skills/{skillId}` |
| `removeSkill(wfId, skillId)` | `DELETE /api/workflows/{wfId}/skills/{skillId}` |
| `listTasks(wfId)` | `GET /api/tasks/workflow/{wfId}` |
| `waitForCompletion(id, …)` | polls `GET /api/workflows/{id}` |
| `stream(id, …)` | `GET /api/workflows/{id}/stream` (SSE) |

### `knowledgeItems`
| Method | Endpoint |
|---|---|
| `list(…)` | `GET /api/knowledge-items` |
| `get(id)` | `GET /api/knowledge-items/{id}` |
| `create(payload)` | `POST /api/knowledge-items` |
| `update(id, payload)` | `PUT /api/knowledge-items/{id}` |
| `delete(id)` | `DELETE /api/knowledge-items/{id}` |
| `query(tags:…)` | `POST /api/knowledge-items/query` |
| `upload(sourceId:…, bytes:…)` | `POST /api/knowledge-items/upload` (multipart) |
| `download(id)` | `GET /api/knowledge-items/{id}/content` |

### Other resources

`agents`, `skills`, `mcps`, `knowledgeSources`, `tasks`, `providers`,
`tokens`, `models` — all expose standard `list / get / create / update / delete`
operations and any endpoint-specific extras (import/export, test connections, etc.).

## Running the tests

```sh
cd packages/flutter
dart pub get
dart test
```

## License

MIT — see [LICENSE](../../LICENSE).
