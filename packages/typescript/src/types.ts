export type JsonPrimitive = boolean | number | string | null;
export type JsonValue = JsonPrimitive | JsonValue[] | { [key: string]: JsonValue };

export type RequestMethod = 'DELETE' | 'GET' | 'PATCH' | 'POST' | 'PUT';
export type FetchLike = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;
export type RequestHeaders = Record<string, string | undefined>;
export type QueryParamValue = boolean | Date | number | string | null | undefined;
export type QueryParams = Record<string, QueryParamValue | QueryParamValue[]>;

export interface ResourceRecord {
  id?: string;
  created_at?: string;
  updated_at?: string;
  [key: string]: unknown;
}

export interface HealthResponse extends ResourceRecord {
  status?: string;
}

export interface UsageStats extends ResourceRecord {
  total_premium_requests?: number;
  total_input_tokens?: number;
  total_output_tokens?: number;
  total_cache_read_tokens?: number;
  total_cache_write_tokens?: number;
  total_cost?: number;
}

export interface WorkflowMessage extends ResourceRecord {
  role: string;
  content?: string | null;
  tool_calls?: Record<string, unknown>[] | null;
  tool_call_id?: string | null;
  name?: string | null;
}

export interface WorkflowLogEntry extends ResourceRecord {
  timestamp: string;
  event: string;
  detail: string;
}

export type WorkflowStatus =
  | 'active'
  | 'inactive'
  | string;

export interface Workflow extends ResourceRecord {
  id: string;
  title?: string | null;
  agent_id: string;
  github_user?: string;
  model: string;
  max_turns: number;
  current_turn: number;
  session_id?: string | null;
  skill_ids: string[];
  skill_tags?: string[];
  status: WorkflowStatus;
  output_format: string;
  infinite_session?: boolean;
  caveman?: boolean;
  bypass_memory?: boolean;
  auto_memory?: boolean;
  tsv_tool_results?: boolean;
  reasoning_effort?: string | null;
  guardrail_ids?: string[];
  guardrail_tags?: string[];
  repo_url?: string | null;
  repo_branch?: string | null;
  repo_token_name?: string | null;
  usage?: UsageStats | null;
  logs: WorkflowLogEntry[];
  messages: WorkflowMessage[];
  task_count?: number;
  last_task_status?: string | null;
  last_task_at?: string | null;
  webhook_url?: string | null;
}

export interface WorkflowCreateInput extends ResourceRecord {
  agent_id: string;
  title?: string | null;
  max_turns?: number;
  output_format?: string;
  model?: string | null;
  skill_ids?: string[];
  skill_tags?: string[];
  infinite_session?: boolean;
  caveman?: boolean;
  bypass_memory?: boolean;
  auto_memory?: boolean;
  tsv_tool_results?: boolean;
  reasoning_effort?: string | null;
  guardrail_ids?: string[];
  guardrail_tags?: string[];
  repo_url?: string | null;
  repo_branch?: string | null;
  repo_token_name?: string | null;
  webhook_url?: string | null;
}

export interface WorkflowUpdateInput extends Partial<WorkflowCreateInput> {
  status?: WorkflowStatus;
}

export interface WorkflowPromptInput extends ResourceRecord {
  prompt?: string | null;
  request?: Record<string, unknown> | null;
  reasoning_effort?: string | null;
}

export interface PromptResponse extends ResourceRecord {
  workflow_id: string;
  status: WorkflowStatus;
  current_turn: number;
  max_turns: number;
  response?: string | null;
  output_format: string;
  infinite_session?: boolean;
  caveman?: boolean;
  tsv_tool_results?: boolean;
  usage?: UsageStats | null;
  logs: WorkflowLogEntry[];
  messages: WorkflowMessage[];
}

export type WorkflowStreamEventType =
  | 'log'
  | 'message'
  | 'message_delta'
  | 'output_guardrail_violation'
  | 'progress'
  | 'status'
  | 'usage'
  | string;

export interface WorkflowStreamEvent<TData = unknown> extends ResourceRecord {
  id: string;
  type: WorkflowStreamEventType;
  data: TData;
  timestamp: string;
}

export interface TodoProgressItem extends ResourceRecord {
  id: string;
  title: string;
  status: string;
}

export interface TaskProgress extends ResourceRecord {
  todos?: TodoProgressItem[];
  current_step?: string | null;
  percent_complete?: number | null;
}

export interface TaskSummary extends ResourceRecord {
  id: string;
  workflow_id: string;
  workflow_title?: string | null;
  agent_name?: string | null;
  prompt?: string | null;
  status: string;
  worker?: string | null;
  model?: string | null;
  reasoning_effort?: string | null;
  tool_calls?: number | null;
  started_at?: string | null;
  finished_at?: string | null;
  elapsed_seconds?: number | null;
  created_at?: string;
}

export interface TaskExecution extends TaskSummary {
  celery_task_id?: string | null;
  response?: string | null;
  progress?: TaskProgress | null;
  logs?: WorkflowLogEntry[];
  messages?: WorkflowMessage[];
  usage?: UsageStats | null;
}

export interface KnowledgeSource extends ResourceRecord {
  id: string;
  name: string;
  description?: string | null;
  source_type: string;
  connection_config: Record<string, unknown>;
  tags?: string[];
  status?: string;
  last_error?: string | null;
}

export interface KnowledgeSourceCreateInput extends ResourceRecord {
  name: string;
  description?: string | null;
  source_type: string;
  connection_config: Record<string, unknown>;
  tags?: string[];
}

export interface KnowledgeSourceUpdateInput extends Partial<KnowledgeSourceCreateInput> {}

export interface KnowledgeSourceTestResponse extends ResourceRecord {
  success?: boolean;
  message?: string;
  [key: string]: unknown;
}

export interface KnowledgeItem extends ResourceRecord {
  id: string;
  source_id: string;
  name: string;
  content_type?: string | null;
  text_content?: string | null;
  file_id?: string | null;
  file_name?: string | null;
  file_size?: number | null;
  mime_type?: string | null;
  tags?: string[];
  metadata?: Record<string, unknown> | null;
}

export interface KnowledgeItemCreateInput extends ResourceRecord {
  source_id: string;
  name: string;
  content_type?: 'text';
  text_content?: string | null;
  tags?: string[];
  metadata?: Record<string, unknown>;
}

export interface KnowledgeItemQueryInput extends ResourceRecord {
  tags?: string[];
  limit?: number;
}

export interface KnowledgeItemQueryResponse extends ResourceRecord {
  items: KnowledgeItem[];
}

export interface KnowledgeItemUploadInput extends ResourceRecord {
  sourceId: string;
  file: Blob | Uint8Array | ArrayBuffer;
  fileName?: string;
  contentType?: string;
  tags?: string[];
  metadata?: Record<string, unknown>;
}

export interface DownloadedKnowledgeItem {
  data: Uint8Array;
  contentType?: string;
  fileName?: string;
  response: Response;
}

// ---------------------------------------------------------------------------
// Guardrails
// ---------------------------------------------------------------------------

export type GuardrailType = 'prompt' | 'request' | 'output' | string;

export interface PromptGuardrailConfig extends ResourceRecord {
  forbidden_patterns?: string[];
  required_patterns?: string[];
  max_length?: number | null;
  min_length?: number | null;
}

export interface RequestGuardrailConfig extends ResourceRecord {
  json_schema?: Record<string, unknown>;
}

export interface OutputGuardrailConfig extends ResourceRecord {
  forbidden_patterns?: string[];
  required_patterns?: string[];
  max_length?: number | null;
  pii_detection?: boolean;
  must_be_valid_json?: boolean;
}

export interface Guardrail extends ResourceRecord {
  id: string;
  name: string;
  description?: string;
  guardrail_type: GuardrailType;
  tags?: string[];
  enabled?: boolean;
  prompt_config?: PromptGuardrailConfig | null;
  request_config?: RequestGuardrailConfig | null;
  output_config?: OutputGuardrailConfig | null;
  created_at: string;
  updated_at: string;
}

export interface GuardrailCreateInput extends ResourceRecord {
  name: string;
  description?: string;
  guardrail_type: GuardrailType;
  tags?: string[];
  enabled?: boolean;
  prompt_config?: PromptGuardrailConfig | null;
  request_config?: RequestGuardrailConfig | null;
  output_config?: OutputGuardrailConfig | null;
}

export interface GuardrailUpdateInput extends Partial<GuardrailCreateInput> {}

// ---------------------------------------------------------------------------
// Memories
// ---------------------------------------------------------------------------

export type MemoryScope = 'short_term' | 'long_term' | 'episodic' | string;

export interface Memory extends ResourceRecord {
  id: string;
  agent_id: string;
  scope: MemoryScope;
  key: string;
  value: string;
  embedding?: number[] | null;
  metadata?: Record<string, unknown>;
  ttl?: string | null;
  created_at: string;
  updated_at: string;
}

export interface MemoryCreateInput extends ResourceRecord {
  agent_id: string;
  scope: MemoryScope;
  key: string;
  value: string;
  embedding?: number[] | null;
  metadata?: Record<string, unknown>;
  ttl?: string | null;
}

export interface MemoryUpdateInput extends Partial<Omit<MemoryCreateInput, 'agent_id'>> {}

export interface MemorySearchInput extends ResourceRecord {
  agent_id: string;
  query: string;
  scope?: MemoryScope | null;
  limit?: number;
}

// ---------------------------------------------------------------------------
// Scheduled Agents
// ---------------------------------------------------------------------------

export type ScheduleInterval = 'minutes' | 'hours' | 'days' | 'weeks' | string;

export interface ScheduledAgent extends ResourceRecord {
  id: string;
  name: string;
  workflow_id: string;
  prompt: string;
  interval_value: number;
  interval_unit: ScheduleInterval;
  start_at: string;
  end_at?: string | null;
  enabled?: boolean;
  last_run_at?: string | null;
  next_run_at?: string | null;
  created_at: string;
  updated_at: string;
}

export interface ScheduledAgentCreateInput extends ResourceRecord {
  name: string;
  workflow_id: string;
  prompt: string;
  interval_value: number;
  interval_unit?: ScheduleInterval;
  start_at: string;
  end_at?: string | null;
}

export interface ScheduledAgentUpdateInput extends Partial<Omit<ScheduledAgentCreateInput, 'workflow_id'>> {}

// ---------------------------------------------------------------------------
// Custom Tools
// ---------------------------------------------------------------------------

export interface CustomTool extends ResourceRecord {
  id: string;
  name: string;
  description?: string;
  source_code: string;
  parameters_schema?: Record<string, unknown>;
  env_config?: Record<string, string>;
  tags?: string[];
  is_enabled?: boolean;
  is_plugin?: boolean;
  created_at: string;
  updated_at: string;
}

export interface CustomToolCreateInput extends ResourceRecord {
  name: string;
  description?: string;
  source_code: string;
  parameters_schema?: Record<string, unknown>;
  env_config?: Record<string, string>;
  tags?: string[];
  is_enabled?: boolean;
}

export interface CustomToolUpdateInput extends Partial<CustomToolCreateInput> {}

export interface CustomToolRunInput extends ResourceRecord {
  arguments?: Record<string, unknown>;
}

export interface CustomToolRunResponse extends ResourceRecord {
  tool_name: string;
  result?: unknown;
  success: boolean;
  error?: string | null;
}

export interface CustomToolValidateInput extends ResourceRecord {
  source_code: string;
  name: string;
}

export interface CustomToolValidateResponse extends ResourceRecord {
  valid: boolean;
  inferred_schema?: Record<string, unknown> | null;
  error?: string | null;
}

export interface EnvVarEntry extends ResourceRecord {
  env_var: string;
  current_token?: string | null;
  template: string;
}

export interface EnvMappingTokenRef extends ResourceRecord {
  id: string;
  name: string;
  description?: string;
  masked_value: string;
}

export interface EnvMappingResponse extends ResourceRecord {
  tool_id: string;
  tool_name: string;
  env_vars?: EnvVarEntry[];
  available_tokens?: EnvMappingTokenRef[];
}

export interface EnvMappingUpdateInput extends ResourceRecord {
  env_var_mapping: Record<string, string>;
}

export interface CustomToolUploadInput {
  file: Blob | Uint8Array | ArrayBuffer;
  fileName?: string;
  name: string;
  description?: string;
  tags?: string[];
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

export interface ChatInput extends ResourceRecord {
  message: string;
  session_id?: string | null;
}

export interface ChatMessageRecord extends ResourceRecord {
  id: string;
  role: string;
  content: string;
  usage?: Record<string, unknown> | null;
  created_at: string;
}

export interface ChatSessionResponse extends ResourceRecord {
  id: string;
  agent_id: string;
  title?: string | null;
  message_count?: number;
  created_at: string;
  updated_at: string;
}

export interface ChatSessionDetail extends ChatSessionResponse {
  messages?: ChatMessageRecord[];
}

export interface ChatStartInput extends ResourceRecord {
  agent_id: string;
}

export interface ChatStartResponse extends ResourceRecord {
  workflow_id: string;
  agent_name: string;
  agent_id: string;
}

// ---------------------------------------------------------------------------
// Export / Import
// ---------------------------------------------------------------------------

export interface FullExportBundle extends ResourceRecord {
  version?: string;
  exported_at?: string | null;
  resource_type?: string;
  skills?: ResourceRecord[];
  agents?: ResourceRecord[];
  workflows?: ResourceRecord[];
  knowledge_sources?: ResourceRecord[];
}

export interface ImportResult extends ResourceRecord {
  created?: number;
  updated?: number;
  skipped?: number;
  errors?: string[];
}

export interface BundleImportResult extends ResourceRecord {
  skills?: ImportResult;
  agents?: ImportResult;
  workflows?: ImportResult;
  knowledge_sources?: ImportResult;
}

