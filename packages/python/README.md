# TBD Agents Python SDK

GitHub Packages does not provide a native Python package registry. Published Python wheels and source distributions for this SDK are attached to [GitHub Releases](https://github.com/naaico-tech/tbd-agents-sdk/releases).

## Install a published release

1. Download the wheel or source distribution for the version you want from GitHub Releases.
2. Install the downloaded artifact locally:

```bash
pip install ./tbd_agents-<version>-py3-none-any.whl
# or
pip install ./tbd_agents-<version>.tar.gz
```

## Install from the workspace

```bash
pip install ./packages/python
```

```python
from tbd_agents import TbdAgentsClient, WorkflowCreate

with TbdAgentsClient(
    base_url="http://localhost:8000",
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
    print(len(agents))
    print(task.status)
```

Highlights:

- `/api` aware client with `/health` handled outside the API base
- optional bearer token authentication for secured deployments
- typed resource helpers for common TBD Agents routes
- workflow prompt helpers, polling, and SSE streaming
- multipart knowledge item upload and binary download helpers
- low-level request escape hatch for advanced routes

For deployments that require authentication, pass a token explicitly:

```python
from tbd_agents import TbdAgentsClient

client = TbdAgentsClient(
    base_url="https://agents.example.com",
    token="YOUR_GITHUB_TOKEN",
)
```
