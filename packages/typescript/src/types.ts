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
