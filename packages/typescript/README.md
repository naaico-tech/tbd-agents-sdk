# TBD Agents TypeScript SDK

This package is prepared for GitHub Packages publication under the `@naaico-tech` scope.

## Install from GitHub Packages

Add the `naaico-tech` scope to your npm configuration and provide a token with `read:packages` access:

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

## Install from the workspace

```bash
cd packages/typescript && npm install
```

Highlights:

- `/api` aware client with `/health` handled outside the API base
- bearer token authentication
- typed resource helpers for common TBD Agents routes
- workflow prompt helpers, polling, and SSE streaming
- multipart knowledge item upload and binary download helpers
- low-level request escape hatch for advanced routes
