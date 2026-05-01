# TBD Agents SDKs

SDK workspace for integrating [TBD Agents](https://github.com/naaico-tech/tbd-agents) into Python and TypeScript applications with minimal setup.

## Packages

| Package | Path | Publication |
| --- | --- | --- |
| Python SDK | `packages/python` | Wheels and sdists attached to GitHub Releases |
| TypeScript SDK | `packages/typescript` | GitHub Packages npm package: `@naaico-tech/typescript-sdk` |

## What the SDKs cover

Both SDKs provide:

- bearer-token authentication and base URL handling
- first-class clients for `agents`, `skills`, `mcps`, `knowledge_sources`, `knowledge_items`, `workflows`, `tasks`, `providers`, `tokens`, `models`, and `health`
- workflow prompt helpers, polling helpers, and SSE streaming support
- multipart knowledge item uploads and binary downloads
- a low-level request escape hatch for advanced routes

## Publication model

- The TypeScript SDK is published to GitHub Packages under the `@naaico-tech` scope.
- GitHub Packages does not provide a native Python package registry, so Python wheels and source distributions are attached to GitHub Releases instead.

## Python quick start

Published release artifacts:

1. Download the latest wheel or source distribution from [GitHub Releases](https://github.com/naaico-tech/tbd-agents-sdk/releases).
2. Install the downloaded artifact:

```bash
pip install ./tbd_agents-<version>-py3-none-any.whl
# or
pip install ./tbd_agents-<version>.tar.gz
```

Local workspace source install:

```bash
pip install ./packages/python
```

```python
from tbd_agents import TbdAgentsClient, WorkflowCreate

with TbdAgentsClient(
    base_url="http://localhost:8000",
    token="YOUR_GITHUB_TOKEN",
) as client:
    health = client.health.get()
    agents = client.agents.list()

    workflow = client.workflows.create(
        WorkflowCreate(
            agent_id="AGENT_ID",
            title="SDK onboarding",
            output_format="markdown",
        )
    )

    task = client.workflows.run_prompt(
        workflow.id,
        prompt="Summarize the latest workflow state.",
    )

    print(health.status)
    print(task.status)
```

## TypeScript quick start

Published package from GitHub Packages:

```ini
@naaico-tech:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GH_PACKAGES_TOKEN}
```

```bash
npm install @naaico-tech/typescript-sdk
```

```ts
import { TbdAgentsClient } from "@naaico-tech/typescript-sdk";

const client = new TbdAgentsClient({
  baseUrl: "http://localhost:8000",
  token: process.env.GITHUB_TOKEN!,
});

const health = await client.health.check();
const workflow = await client.workflows.create({
  agent_id: "AGENT_ID",
  title: "SDK onboarding",
  output_format: "markdown",
});

await client.workflows.sendPrompt(workflow.id, {
  prompt: "Summarize the latest workflow state.",
});

for await (const event of client.workflows.stream(workflow.id)) {
  console.log(event.type, event.data);
}

console.log(health.status);
```

Local workspace development install:

```bash
cd packages/typescript && npm install
```

## Workspace commands

```bash
make validate
make clean
```

## Notes

- The upstream API serves `/health` outside `/api`; both clients handle that automatically.
- Workflow run state comes from task execution and stream events, not the workflow's persisted `active`/`inactive` flag.
- The TypeScript package targets runtimes with `fetch`, `FormData`, `Blob`, and web streams support.
