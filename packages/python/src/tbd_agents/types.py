from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator


class StringEnum(str, Enum):
    pass


class ApiModel(BaseModel):
    model_config = ConfigDict(extra="allow", populate_by_name=True)


class HealthStatus(ApiModel):
    status: str


class UsageStats(ApiModel):
    total_premium_requests: float = 0
    total_input_tokens: int = 0
    total_output_tokens: int = 0
    total_cache_read_tokens: int = 0
    total_cache_write_tokens: int = 0
    total_cost: float = 0.0


class LogEntry(ApiModel):
    timestamp: datetime
    event: str
    detail: str


class Message(ApiModel):
    role: str
    content: str | None = None
    tool_calls: list[dict[str, Any]] | None = None
    tool_call_id: str | None = None
    name: str | None = None


class ImportResult(ApiModel):
    created: int = 0
    errors: list[str] = Field(default_factory=list)
    ids: list[str] = Field(default_factory=list)


class TransportType(StringEnum):
    STDIO = "stdio"
    SSE = "sse"
    HTTP = "http"


class McpServerStatus(StringEnum):
    REGISTERED = "registered"
    CONNECTED = "connected"
    ERROR = "error"


class KnowledgeSourceType(StringEnum):
    VECTOR_DB = "vector_db"
    MONGO_DB = "mongo_db"


class KnowledgeSourceStatus(StringEnum):
    REGISTERED = "registered"
    CONNECTED = "connected"
    ERROR = "error"


class KnowledgeContentType(StringEnum):
    TEXT = "text"
    FILE = "file"
    IMAGE = "image"


class ProviderType(StringEnum):
    GITHUB_COPILOT = "github_copilot"
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    AZURE_OPENAI = "azure_openai"
    CUSTOM = "custom"


class WorkflowStatus(StringEnum):
    ACTIVE = "active"
    INACTIVE = "inactive"


class OutputFormat(StringEnum):
    JSON = "json"
    MARKDOWN = "markdown"


class TaskStatus(StringEnum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    HALTED = "halted"
    MAX_TURNS_REACHED = "max_turns_reached"


class TodoItemStatus(StringEnum):
    NOT_STARTED = "not-started"
    IN_PROGRESS = "in-progress"
    COMPLETED = "completed"


class ExportedSkill(ApiModel):
    name: str
    description: str = ""
    instructions: str
    tags: list[str] = Field(default_factory=list)


class SkillCreate(ExportedSkill):
    pass


class SkillUpdate(ApiModel):
    name: str | None = None
    description: str | None = None
    instructions: str | None = None
    tags: list[str] | None = None


class Skill(ApiModel):
    id: str
    name: str
    description: str
    instructions: str
    tags: list[str] = Field(default_factory=list)
    created_at: datetime
    updated_at: datetime


class SkillExportBundle(ApiModel):
    version: str = "1.0"
    exported_at: datetime
    resource_type: str = "skill"
    items: list[ExportedSkill]


class SkillImportBundle(ApiModel):
    items: list[ExportedSkill]


class ExportedAgent(ApiModel):
    name: str
    description: str = ""
    system_prompt: str = "You are a helpful assistant."
    model: str | None = None
    mcp_server_ids: list[str] = Field(default_factory=list)
    mcp_server_tags: list[str] = Field(default_factory=list)
    tool_definitions: list[dict[str, Any]] = Field(default_factory=list)
    knowledge_source_ids: list[str] = Field(default_factory=list)
    knowledge_tags: list[str] = Field(default_factory=list)
    builtin_tools: list[str] = Field(default_factory=list)
    custom_tool_ids: list[str] = Field(default_factory=list)
    provider_id: str | None = None


class AgentCreate(ExportedAgent):
    pass


class AgentUpdate(ApiModel):
    name: str | None = None
    description: str | None = None
    system_prompt: str | None = None
    model: str | None = None
    mcp_server_ids: list[str] | None = None
    mcp_server_tags: list[str] | None = None
    tool_definitions: list[dict[str, Any]] | None = None
    knowledge_source_ids: list[str] | None = None
    knowledge_tags: list[str] | None = None
    builtin_tools: list[str] | None = None
    custom_tool_ids: list[str] | None = None
    provider_id: str | None = None


class Agent(ApiModel):
    id: str
    name: str
    description: str
    system_prompt: str
    model: str | None = None
    mcp_server_ids: list[str] = Field(default_factory=list)
    mcp_server_tags: list[str] = Field(default_factory=list)
    tool_definitions: list[dict[str, Any]] = Field(default_factory=list)
    knowledge_source_ids: list[str] = Field(default_factory=list)
    knowledge_tags: list[str] = Field(default_factory=list)
    builtin_tools: list[str] = Field(default_factory=list)
    custom_tool_ids: list[str] = Field(default_factory=list)
    provider_id: str | None = None
    created_at: datetime
    updated_at: datetime


class AgentExportBundle(ApiModel):
    version: str = "1.0"
    exported_at: datetime
    resource_type: str = "agent"
    items: list[ExportedAgent]


class AgentImportBundle(ApiModel):
    items: list[ExportedAgent]


class McpServerCreate(ApiModel):
    name: str
    transport_type: TransportType | str
    connection_config: dict[str, Any]
    allowed_tools: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)


class McpServerUpdate(ApiModel):
    name: str | None = None
    transport_type: TransportType | str | None = None
    connection_config: dict[str, Any] | None = None
    allowed_tools: list[str] | None = None
    tags: list[str] | None = None


class McpServer(ApiModel):
    id: str
    name: str
    transport_type: TransportType | str
    connection_config: dict[str, Any]
    allowed_tools: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    status: McpServerStatus | str
    last_error: str | None = None
    created_at: datetime
    updated_at: datetime


class McpTestResult(ApiModel):
    success: bool
    tools: list[dict[str, Any]] = Field(default_factory=list)
    error: str | None = None


class McpTools(ApiModel):
    tools: list[dict[str, Any]] = Field(default_factory=list)


class AllowedToolsUpdate(ApiModel):
    allowed_tools: list[str] = Field(default_factory=list)


class KnowledgeSourceCreate(ApiModel):
    name: str
    description: str = ""
    source_type: KnowledgeSourceType | str
    connection_config: dict[str, Any] = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)


class KnowledgeSourceUpdate(ApiModel):
    name: str | None = None
    description: str | None = None
    source_type: KnowledgeSourceType | str | None = None
    connection_config: dict[str, Any] | None = None
    tags: list[str] | None = None


class KnowledgeSource(ApiModel):
    id: str
    name: str
    description: str
    source_type: KnowledgeSourceType | str
    connection_config: dict[str, Any] = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)
    status: KnowledgeSourceStatus | str
    last_error: str | None = None
    created_at: datetime
    updated_at: datetime


class KnowledgeSourceTestResult(ApiModel):
    success: bool
    error: str | None = None


class ExportedKnowledgeSource(ApiModel):
    name: str
    description: str = ""
    source_type: KnowledgeSourceType | str
    connection_config: dict[str, Any] = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)


class KnowledgeSourceExportBundle(ApiModel):
    version: str = "1.0"
    exported_at: datetime
    resource_type: str = "knowledge_source"
    items: list[ExportedKnowledgeSource]


class KnowledgeSourceImportBundle(ApiModel):
    items: list[ExportedKnowledgeSource]


class KnowledgeItemCreate(ApiModel):
    source_id: str
    name: str
    content_type: KnowledgeContentType | str = KnowledgeContentType.TEXT
    text_content: str | None = None
    tags: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


class KnowledgeItemUpdate(ApiModel):
    name: str | None = None
    text_content: str | None = None
    tags: list[str] | None = None
    metadata: dict[str, Any] | None = None


class KnowledgeItem(ApiModel):
    id: str
    source_id: str
    name: str
    content_type: KnowledgeContentType | str
    text_content: str | None = None
    file_id: str | None = None
    file_name: str | None = None
    file_size: int | None = None
    mime_type: str | None = None
    tags: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)
    created_at: datetime
    updated_at: datetime


class KnowledgeQueryRequest(ApiModel):
    tags: list[str]
    limit: int = 10


class KnowledgeQueryResponse(ApiModel):
    items: list[KnowledgeItem] = Field(default_factory=list)


class DownloadedContent(ApiModel):
    content: bytes
    content_type: str | None = None
    filename: str | None = None


class ProviderCreate(ApiModel):
    name: str
    provider_type: ProviderType | str
    api_key_token_name: str
    base_url: str | None = None
    azure_api_version: str = "2024-12-01-preview"
    azure_deployment: str | None = None
    description: str = ""


class ProviderUpdate(ApiModel):
    name: str | None = None
    provider_type: ProviderType | str | None = None
    api_key_token_name: str | None = None
    base_url: str | None = None
    azure_api_version: str | None = None
    azure_deployment: str | None = None
    description: str | None = None


class Provider(ApiModel):
    id: str
    name: str
    provider_type: ProviderType | str
    api_key_token_name: str
    base_url: str | None = None
    azure_api_version: str = "2024-12-01-preview"
    azure_deployment: str | None = None
    description: str
    created_at: datetime
    updated_at: datetime


class TokenCreate(ApiModel):
    name: str
    value: str
    description: str = ""


class TokenUpdate(ApiModel):
    value: str | None = None
    description: str | None = None


class Token(ApiModel):
    id: str
    name: str
    description: str
    masked_value: str
    created_by: str
    created_at: datetime
    updated_at: datetime


class WorkflowCreate(ApiModel):
    title: str | None = None
    agent_id: str
    max_turns: int | None = None
    output_format: OutputFormat | str = OutputFormat.JSON
    model: str | None = None
    skill_ids: list[str] = Field(default_factory=list)
    skill_tags: list[str] = Field(default_factory=list)
    infinite_session: bool = True
    caveman: bool = False
    bypass_memory: bool = False
    auto_memory: bool = False
    tsv_tool_results: bool = False
    reasoning_effort: str | None = None
    guardrail_ids: list[str] = Field(default_factory=list)
    guardrail_tags: list[str] = Field(default_factory=list)
    repo_url: str | None = None
    repo_branch: str | None = None
    repo_token_name: str | None = None
    repository_ids: list[str] = Field(default_factory=list)
    repository_tags: list[str] = Field(default_factory=list)
    webhook_url: str | None = None


class WorkflowUpdate(ApiModel):
    title: str | None = None
    agent_id: str | None = None
    max_turns: int | None = None
    output_format: OutputFormat | str | None = None
    model: str | None = None
    skill_ids: list[str] | None = None
    skill_tags: list[str] | None = None
    infinite_session: bool | None = None
    caveman: bool | None = None
    bypass_memory: bool | None = None
    auto_memory: bool | None = None
    tsv_tool_results: bool | None = None
    reasoning_effort: str | None = None
    guardrail_ids: list[str] | None = None
    guardrail_tags: list[str] | None = None
    repo_url: str | None = None
    repo_branch: str | None = None
    repo_token_name: str | None = None
    repository_ids: list[str] | None = None
    repository_tags: list[str] | None = None
    status: WorkflowStatus | str | None = None
    webhook_url: str | None = None


class PromptRequest(ApiModel):
    prompt: str | None = None
    request: dict[str, Any] | None = None
    reasoning_effort: str | None = None

    @model_validator(mode="after")
    def validate_content(self) -> "PromptRequest":
        if self.prompt is None and self.request is None:
            raise ValueError("either prompt or request must be provided")
        return self


class PromptResponse(ApiModel):
    workflow_id: str
    status: str
    current_turn: int
    max_turns: int
    response: str | None = None
    output_format: OutputFormat | str
    infinite_session: bool = True
    caveman: bool = False
    tsv_tool_results: bool = False
    usage: UsageStats | None = None
    logs: list[LogEntry] = Field(default_factory=list)
    messages: list[Message] = Field(default_factory=list)


class Workflow(ApiModel):
    id: str
    title: str | None = None
    agent_id: str
    github_user: str
    model: str
    max_turns: int
    current_turn: int
    session_id: str | None = None
    skill_ids: list[str] = Field(default_factory=list)
    skill_tags: list[str] = Field(default_factory=list)
    status: WorkflowStatus | str
    output_format: OutputFormat | str
    infinite_session: bool = True
    caveman: bool = False
    bypass_memory: bool = False
    auto_memory: bool = False
    tsv_tool_results: bool = False
    reasoning_effort: str | None = None
    guardrail_ids: list[str] = Field(default_factory=list)
    guardrail_tags: list[str] = Field(default_factory=list)
    repo_url: str | None = None
    repo_branch: str | None = None
    repo_token_name: str | None = None
    repository_ids: list[str] = Field(default_factory=list)
    repository_tags: list[str] = Field(default_factory=list)
    usage: UsageStats | None = None
    logs: list[LogEntry] = Field(default_factory=list)
    messages: list[Message] = Field(default_factory=list)
    task_count: int = 0
    last_task_status: str | None = None
    last_task_at: datetime | None = None
    webhook_url: str | None = None
    created_at: datetime
    updated_at: datetime


class ExportedWorkflow(ApiModel):
    title: str | None = None
    agent_id: str
    model: str | None = None
    max_turns: int = 5
    skill_ids: list[str] = Field(default_factory=list)
    skill_tags: list[str] = Field(default_factory=list)
    output_format: OutputFormat | str = OutputFormat.JSON
    infinite_session: bool = True
    caveman: bool = False
    bypass_memory: bool = False
    auto_memory: bool = False
    tsv_tool_results: bool = False
    reasoning_effort: str | None = None
    guardrail_ids: list[str] = Field(default_factory=list)
    guardrail_tags: list[str] = Field(default_factory=list)
    repo_url: str | None = None
    repo_branch: str | None = None
    repo_token_name: str | None = None
    repository_ids: list[str] = Field(default_factory=list)
    repository_tags: list[str] = Field(default_factory=list)
    webhook_url: str | None = None


class WorkflowExportBundle(ApiModel):
    version: str = "1.0"
    exported_at: datetime
    resource_type: str = "workflow"
    items: list[ExportedWorkflow]


class WorkflowImportBundle(ApiModel):
    items: list[ExportedWorkflow]


class TodoItem(ApiModel):
    id: int
    title: str
    status: TodoItemStatus | str


class TaskProgress(ApiModel):
    todos: list[TodoItem] = Field(default_factory=list)
    current_step: int | None = None
    percent_complete: float = 0.0


class TaskExecution(ApiModel):
    id: str
    workflow_id: str
    workflow_title: str | None = None
    agent_name: str | None = None
    prompt: str
    status: TaskStatus | str
    celery_task_id: str | None = None
    worker: str | None = None
    model: str | None = None
    reasoning_effort: str | None = None
    tool_calls: int = 0
    response: str | None = None
    progress: TaskProgress | None = None
    logs: list[LogEntry] = Field(default_factory=list)
    messages: list[Message] = Field(default_factory=list)
    usage: UsageStats | None = None
    started_at: datetime | None = None
    finished_at: datetime | None = None
    elapsed_seconds: float | None = None
    created_at: datetime


class TaskExecutionSummary(ApiModel):
    id: str
    workflow_id: str
    workflow_title: str | None = None
    agent_name: str | None = None
    prompt: str
    status: TaskStatus | str
    worker: str | None = None
    model: str | None = None
    reasoning_effort: str | None = None
    tool_calls: int = 0
    started_at: datetime | None = None
    finished_at: datetime | None = None
    elapsed_seconds: float | None = None
    created_at: datetime


class WorkflowStreamEvent(ApiModel):
    id: int | str | None = None
    type: str
    data: Any = None
    timestamp: datetime | str | None = None


class DetailResponse(ApiModel):
    detail: str


# ---------------------------------------------------------------------------
# Guardrails
# ---------------------------------------------------------------------------


class GuardrailType(StringEnum):
    PROMPT = "prompt"
    REQUEST = "request"
    OUTPUT = "output"


class PromptGuardrailConfig(ApiModel):
    forbidden_patterns: list[str] = Field(default_factory=list)
    required_patterns: list[str] = Field(default_factory=list)
    max_length: int | None = None
    min_length: int | None = None


class RequestGuardrailConfig(ApiModel):
    json_schema: dict[str, Any] = Field(default_factory=dict)


class OutputGuardrailConfig(ApiModel):
    forbidden_patterns: list[str] = Field(default_factory=list)
    required_patterns: list[str] = Field(default_factory=list)
    max_length: int | None = None
    pii_detection: bool = False
    must_be_valid_json: bool = False


class GuardrailCreate(ApiModel):
    name: str
    description: str = ""
    guardrail_type: GuardrailType
    tags: list[str] = Field(default_factory=list)
    enabled: bool = True
    prompt_config: PromptGuardrailConfig | None = None
    request_config: RequestGuardrailConfig | None = None
    output_config: OutputGuardrailConfig | None = None


class GuardrailUpdate(ApiModel):
    name: str | None = None
    description: str | None = None
    guardrail_type: GuardrailType | None = None
    tags: list[str] | None = None
    enabled: bool | None = None
    prompt_config: PromptGuardrailConfig | None = None
    request_config: RequestGuardrailConfig | None = None
    output_config: OutputGuardrailConfig | None = None


class Guardrail(ApiModel):
    id: str
    name: str
    description: str = ""
    guardrail_type: GuardrailType
    tags: list[str] = Field(default_factory=list)
    enabled: bool = True
    prompt_config: PromptGuardrailConfig | None = None
    request_config: RequestGuardrailConfig | None = None
    output_config: OutputGuardrailConfig | None = None
    created_at: datetime
    updated_at: datetime


# ---------------------------------------------------------------------------
# Memories
# ---------------------------------------------------------------------------


class MemoryScope(StringEnum):
    SHORT_TERM = "short_term"
    LONG_TERM = "long_term"
    EPISODIC = "episodic"


class MemoryCreate(ApiModel):
    agent_id: str
    scope: MemoryScope
    key: str
    value: str
    embedding: list[float] | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    ttl: datetime | None = None


class MemoryUpdate(ApiModel):
    scope: MemoryScope | None = None
    key: str | None = None
    value: str | None = None
    embedding: list[float] | None = None
    metadata: dict[str, Any] | None = None
    ttl: datetime | None = None


class Memory(ApiModel):
    id: str
    agent_id: str
    scope: MemoryScope
    key: str
    value: str
    embedding: list[float] | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
    ttl: datetime | None = None
    created_at: datetime
    updated_at: datetime


class MemorySearchRequest(ApiModel):
    agent_id: str
    query: str
    scope: MemoryScope | None = None
    limit: int = 10


# ---------------------------------------------------------------------------
# Scheduled Agents
# ---------------------------------------------------------------------------


class ScheduleInterval(StringEnum):
    MINUTES = "minutes"
    HOURS = "hours"
    DAYS = "days"
    WEEKS = "weeks"


class ScheduledAgentCreate(ApiModel):
    name: str
    workflow_id: str
    prompt: str
    interval_value: int
    interval_unit: ScheduleInterval = ScheduleInterval.HOURS
    start_at: datetime
    end_at: datetime | None = None


class ScheduledAgentUpdate(ApiModel):
    name: str | None = None
    prompt: str | None = None
    interval_value: int | None = None
    interval_unit: ScheduleInterval | None = None
    start_at: datetime | None = None
    end_at: datetime | None = None


class ScheduledAgent(ApiModel):
    id: str
    name: str
    workflow_id: str
    prompt: str
    interval_value: int
    interval_unit: ScheduleInterval
    start_at: datetime
    end_at: datetime | None = None
    enabled: bool = True
    last_run_at: datetime | None = None
    next_run_at: datetime | None = None
    created_at: datetime
    updated_at: datetime


# ---------------------------------------------------------------------------
# Custom Tools
# ---------------------------------------------------------------------------


class CustomToolCreate(ApiModel):
    name: str
    description: str = ""
    source_code: str
    parameters_schema: dict[str, Any] = Field(default_factory=dict)
    env_config: dict[str, str] = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)
    is_enabled: bool = True


class CustomToolUpdate(ApiModel):
    name: str | None = None
    description: str | None = None
    source_code: str | None = None
    parameters_schema: dict[str, Any] | None = None
    env_config: dict[str, str] | None = None
    tags: list[str] | None = None
    is_enabled: bool | None = None


class CustomTool(ApiModel):
    id: str
    name: str
    description: str = ""
    source_code: str
    parameters_schema: dict[str, Any] = Field(default_factory=dict)
    env_config: dict[str, str] = Field(default_factory=dict)
    tags: list[str] = Field(default_factory=list)
    is_enabled: bool = True
    is_plugin: bool = False
    created_at: datetime
    updated_at: datetime


class CustomToolRunRequest(ApiModel):
    arguments: dict[str, Any] = Field(default_factory=dict)


class CustomToolRunResponse(ApiModel):
    tool_name: str
    result: Any = None
    success: bool
    error: str | None = None


class CustomToolValidateRequest(ApiModel):
    source_code: str
    name: str


class CustomToolValidateResponse(ApiModel):
    valid: bool
    inferred_schema: dict[str, Any] | None = None
    error: str | None = None


class EnvVarEntry(ApiModel):
    env_var: str
    current_token: str | None = None
    template: str


class EnvMappingTokenRef(ApiModel):
    id: str
    name: str
    description: str = ""
    masked_value: str


class EnvMappingResponse(ApiModel):
    tool_id: str
    tool_name: str
    env_vars: list[EnvVarEntry] = Field(default_factory=list)
    available_tokens: list[EnvMappingTokenRef] = Field(default_factory=list)


class EnvMappingUpdate(ApiModel):
    env_var_mapping: dict[str, str] = Field(default_factory=dict)


# ---------------------------------------------------------------------------
# Chat
# ---------------------------------------------------------------------------


class ChatRequest(ApiModel):
    message: str
    session_id: str | None = None


class ChatMessageRecord(ApiModel):
    id: str
    role: str
    content: str
    usage: dict[str, Any] | None = None
    created_at: datetime


class ChatSessionResponse(ApiModel):
    id: str
    agent_id: str
    title: str | None = None
    message_count: int = 0
    created_at: datetime
    updated_at: datetime


class ChatSessionDetail(ChatSessionResponse):
    messages: list[ChatMessageRecord] = Field(default_factory=list)


class ChatStartRequest(ApiModel):
    agent_id: str


class ChatStartResponse(ApiModel):
    workflow_id: str
    agent_name: str
    agent_id: str


# ---------------------------------------------------------------------------
# Full export / import bundle
# ---------------------------------------------------------------------------


class FullExportBundle(ApiModel):
    version: str = "1.0"
    exported_at: datetime | None = None
    resource_type: str = "full"
    skills: list[ExportedSkill] = Field(default_factory=list)
    agents: list[ExportedAgent] = Field(default_factory=list)
    workflows: list[ExportedWorkflow] = Field(default_factory=list)
    knowledge_sources: list[ExportedKnowledgeSource] = Field(default_factory=list)


class BundleImportResult(ApiModel):
    skills: ImportResult = Field(default_factory=ImportResult)
    agents: ImportResult = Field(default_factory=ImportResult)
    workflows: ImportResult = Field(default_factory=ImportResult)
    knowledge_sources: ImportResult = Field(default_factory=ImportResult)

