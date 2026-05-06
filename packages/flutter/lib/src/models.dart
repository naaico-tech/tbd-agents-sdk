/// Typed model classes mirroring the TBD Agents API schema.
///
/// All models accept unknown fields (extra keys are preserved in [extras]).
library;

// ---------------------------------------------------------------------------
// Base helpers
// ---------------------------------------------------------------------------

/// Returns [value] cast to [T], or [defaultValue] if it is `null` or the wrong type.
T _cast<T>(Object? value, T defaultValue) {
  if (value is T) return value;
  return defaultValue;
}

String? _str(Object? v) => v is String ? v : null;
bool _bool(Object? v, {bool fallback = false}) => v is bool ? v : fallback;
int _int(Object? v, {int fallback = 0}) =>
    v is int ? v : (v is num ? v.toInt() : fallback);
double _double(Object? v, {double fallback = 0.0}) =>
    v is double ? v : (v is num ? v.toDouble() : fallback);
List<String> _strList(Object? v) {
  if (v is List) return v.whereType<String>().toList();
  return const [];
}

// ---------------------------------------------------------------------------
// Health
// ---------------------------------------------------------------------------

class HealthStatus {
  const HealthStatus({required this.status, this.extras = const {}});

  factory HealthStatus.fromJson(Map<String, dynamic> json) =>
      HealthStatus(status: _cast<String>(json['status'], 'unknown'), extras: json);

  final String status;
  final Map<String, dynamic> extras;

  Map<String, dynamic> toJson() => {'status': status};
}

// ---------------------------------------------------------------------------
// Usage stats
// ---------------------------------------------------------------------------

class UsageStats {
  const UsageStats({
    this.totalPremiumRequests = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalCacheReadTokens = 0,
    this.totalCacheWriteTokens = 0,
    this.totalCost = 0.0,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) => UsageStats(
        totalPremiumRequests: _double(json['total_premium_requests']),
        totalInputTokens: _int(json['total_input_tokens']),
        totalOutputTokens: _int(json['total_output_tokens']),
        totalCacheReadTokens: _int(json['total_cache_read_tokens']),
        totalCacheWriteTokens: _int(json['total_cache_write_tokens']),
        totalCost: _double(json['total_cost']),
      );

  final double totalPremiumRequests;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalCacheReadTokens;
  final int totalCacheWriteTokens;
  final double totalCost;

  Map<String, dynamic> toJson() => {
        'total_premium_requests': totalPremiumRequests,
        'total_input_tokens': totalInputTokens,
        'total_output_tokens': totalOutputTokens,
        'total_cache_read_tokens': totalCacheReadTokens,
        'total_cache_write_tokens': totalCacheWriteTokens,
        'total_cost': totalCost,
      };
}

// ---------------------------------------------------------------------------
// Log entry / Message
// ---------------------------------------------------------------------------

class LogEntry {
  const LogEntry({required this.timestamp, required this.event, required this.detail});

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        timestamp: _cast<String>(json['timestamp'], ''),
        event: _cast<String>(json['event'], ''),
        detail: _cast<String>(json['detail'], ''),
      );

  final String timestamp;
  final String event;
  final String detail;

  Map<String, dynamic> toJson() => {'timestamp': timestamp, 'event': event, 'detail': detail};
}

class Message {
  const Message({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        role: _cast<String>(json['role'], ''),
        content: _str(json['content']),
        toolCalls: json['tool_calls'] is List
            ? (json['tool_calls'] as List).whereType<Map<String, dynamic>>().toList()
            : null,
        toolCallId: _str(json['tool_call_id']),
        name: _str(json['name']),
      );

  final String role;
  final String? content;
  final List<Map<String, dynamic>>? toolCalls;
  final String? toolCallId;
  final String? name;

  Map<String, dynamic> toJson() => {
        'role': role,
        if (content != null) 'content': content,
        if (toolCalls != null) 'tool_calls': toolCalls,
        if (toolCallId != null) 'tool_call_id': toolCallId,
        if (name != null) 'name': name,
      };
}

// ---------------------------------------------------------------------------
// Import result
// ---------------------------------------------------------------------------

class ImportResult {
  const ImportResult({this.created = 0, this.errors = const [], this.ids = const []});

  factory ImportResult.fromJson(Map<String, dynamic> json) => ImportResult(
        created: _int(json['created']),
        errors: _strList(json['errors']),
        ids: _strList(json['ids']),
      );

  final int created;
  final List<String> errors;
  final List<String> ids;

  Map<String, dynamic> toJson() => {
        'created': created,
        'errors': errors,
        'ids': ids,
      };
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------

class WorkflowCreate {
  const WorkflowCreate({
    required this.agentId,
    this.title,
    this.maxTurns,
    this.outputFormat = 'json',
    this.model,
    this.skillIds = const [],
    this.skillTags = const [],
    this.infiniteSession = true,
    this.caveman = false,
    this.bypassMemory = false,
    this.autoMemory = false,
    this.tsvToolResults = false,
    this.reasoningEffort,
    this.guardrailIds = const [],
    this.guardrailTags = const [],
    this.repoUrl,
    this.repoBranch,
    this.repoTokenName,
    this.repositoryIds = const [],
    this.repositoryTags = const [],
    this.webhookUrl,
  });

  final String agentId;
  final String? title;
  final int? maxTurns;
  final String outputFormat;
  final String? model;
  final List<String> skillIds;
  final List<String> skillTags;
  final bool infiniteSession;
  final bool caveman;
  final bool bypassMemory;
  final bool autoMemory;
  final bool tsvToolResults;
  final String? reasoningEffort;
  final List<String> guardrailIds;
  final List<String> guardrailTags;
  final String? repoUrl;
  final String? repoBranch;
  final String? repoTokenName;
  final List<String> repositoryIds;
  final List<String> repositoryTags;
  final String? webhookUrl;

  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        if (title != null) 'title': title,
        if (maxTurns != null) 'max_turns': maxTurns,
        'output_format': outputFormat,
        if (model != null) 'model': model,
        'skill_ids': skillIds,
        'skill_tags': skillTags,
        'infinite_session': infiniteSession,
        'caveman': caveman,
        'bypass_memory': bypassMemory,
        'auto_memory': autoMemory,
        'tsv_tool_results': tsvToolResults,
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
        'guardrail_ids': guardrailIds,
        'guardrail_tags': guardrailTags,
        if (repoUrl != null) 'repo_url': repoUrl,
        if (repoBranch != null) 'repo_branch': repoBranch,
        if (repoTokenName != null) 'repo_token_name': repoTokenName,
        'repository_ids': repositoryIds,
        'repository_tags': repositoryTags,
        if (webhookUrl != null) 'webhook_url': webhookUrl,
      };
}

class WorkflowUpdate {
  const WorkflowUpdate({
    this.title,
    this.agentId,
    this.maxTurns,
    this.outputFormat,
    this.model,
    this.skillIds,
    this.skillTags,
    this.infiniteSession,
    this.caveman,
    this.bypassMemory,
    this.autoMemory,
    this.tsvToolResults,
    this.reasoningEffort,
    this.guardrailIds,
    this.guardrailTags,
    this.repoUrl,
    this.repoBranch,
    this.repoTokenName,
    this.repositoryIds,
    this.repositoryTags,
    this.status,
    this.webhookUrl,
  });

  final String? title;
  final String? agentId;
  final int? maxTurns;
  final String? outputFormat;
  final String? model;
  final List<String>? skillIds;
  final List<String>? skillTags;
  final bool? infiniteSession;
  final bool? caveman;
  final bool? bypassMemory;
  final bool? autoMemory;
  final bool? tsvToolResults;
  final String? reasoningEffort;
  final List<String>? guardrailIds;
  final List<String>? guardrailTags;
  final String? repoUrl;
  final String? repoBranch;
  final String? repoTokenName;
  final List<String>? repositoryIds;
  final List<String>? repositoryTags;
  final String? status;
  final String? webhookUrl;

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (agentId != null) 'agent_id': agentId,
        if (maxTurns != null) 'max_turns': maxTurns,
        if (outputFormat != null) 'output_format': outputFormat,
        if (model != null) 'model': model,
        if (skillIds != null) 'skill_ids': skillIds,
        if (skillTags != null) 'skill_tags': skillTags,
        if (infiniteSession != null) 'infinite_session': infiniteSession,
        if (caveman != null) 'caveman': caveman,
        if (bypassMemory != null) 'bypass_memory': bypassMemory,
        if (autoMemory != null) 'auto_memory': autoMemory,
        if (tsvToolResults != null) 'tsv_tool_results': tsvToolResults,
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
        if (guardrailIds != null) 'guardrail_ids': guardrailIds,
        if (guardrailTags != null) 'guardrail_tags': guardrailTags,
        if (repoUrl != null) 'repo_url': repoUrl,
        if (repoBranch != null) 'repo_branch': repoBranch,
        if (repoTokenName != null) 'repo_token_name': repoTokenName,
        if (repositoryIds != null) 'repository_ids': repositoryIds,
        if (repositoryTags != null) 'repository_tags': repositoryTags,
        if (status != null) 'status': status,
        if (webhookUrl != null) 'webhook_url': webhookUrl,
      };
}

class Workflow {
  const Workflow({
    required this.id,
    required this.agentId,
    required this.githubUser,
    required this.model,
    required this.maxTurns,
    required this.currentTurn,
    required this.status,
    required this.outputFormat,
    required this.skillIds,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.sessionId,
    this.skillTags = const [],
    this.infiniteSession = true,
    this.caveman = false,
    this.bypassMemory = false,
    this.autoMemory = false,
    this.tsvToolResults = false,
    this.reasoningEffort,
    this.guardrailIds = const [],
    this.guardrailTags = const [],
    this.repoUrl,
    this.repoBranch,
    this.repoTokenName,
    this.repositoryIds = const [],
    this.repositoryTags = const [],
    this.usage,
    this.logs = const [],
    this.messages = const [],
    this.taskCount = 0,
    this.lastTaskStatus,
    this.lastTaskAt,
    this.webhookUrl,
    this.extras = const {},
  });

  factory Workflow.fromJson(Map<String, dynamic> json) => Workflow(
        id: _cast<String>(json['id'], ''),
        agentId: _cast<String>(json['agent_id'], ''),
        githubUser: _cast<String>(json['github_user'], ''),
        model: _cast<String>(json['model'], ''),
        maxTurns: _int(json['max_turns']),
        currentTurn: _int(json['current_turn']),
        status: _cast<String>(json['status'], ''),
        outputFormat: _cast<String>(json['output_format'], 'json'),
        skillIds: _strList(json['skill_ids']),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        title: _str(json['title']),
        sessionId: _str(json['session_id']),
        skillTags: _strList(json['skill_tags']),
        infiniteSession: _bool(json['infinite_session'], fallback: true),
        caveman: _bool(json['caveman']),
        bypassMemory: _bool(json['bypass_memory']),
        autoMemory: _bool(json['auto_memory']),
        tsvToolResults: _bool(json['tsv_tool_results']),
        reasoningEffort: _str(json['reasoning_effort']),
        guardrailIds: _strList(json['guardrail_ids']),
        guardrailTags: _strList(json['guardrail_tags']),
        repoUrl: _str(json['repo_url']),
        repoBranch: _str(json['repo_branch']),
        repoTokenName: _str(json['repo_token_name']),
        repositoryIds: _strList(json['repository_ids']),
        repositoryTags: _strList(json['repository_tags']),
        usage: json['usage'] is Map<String, dynamic>
            ? UsageStats.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        logs: (json['logs'] is List)
            ? (json['logs'] as List).whereType<Map<String, dynamic>>().map(LogEntry.fromJson).toList()
            : const [],
        messages: (json['messages'] is List)
            ? (json['messages'] as List).whereType<Map<String, dynamic>>().map(Message.fromJson).toList()
            : const [],
        taskCount: _int(json['task_count']),
        lastTaskStatus: _str(json['last_task_status']),
        lastTaskAt: _str(json['last_task_at']),
        webhookUrl: _str(json['webhook_url']),
        extras: json,
      );

  final String id;
  final String? title;
  final String agentId;
  final String githubUser;
  final String model;
  final int maxTurns;
  final int currentTurn;
  final String? sessionId;
  final List<String> skillIds;
  final List<String> skillTags;
  final String status;
  final String outputFormat;
  final bool infiniteSession;
  final bool caveman;
  final bool bypassMemory;
  final bool autoMemory;
  final bool tsvToolResults;
  final String? reasoningEffort;
  final List<String> guardrailIds;
  final List<String> guardrailTags;
  final String? repoUrl;
  final String? repoBranch;
  final String? repoTokenName;
  final List<String> repositoryIds;
  final List<String> repositoryTags;
  final UsageStats? usage;
  final List<LogEntry> logs;
  final List<Message> messages;
  final int taskCount;
  final String? lastTaskStatus;
  final String? lastTaskAt;
  final String? webhookUrl;
  final String createdAt;
  final String updatedAt;

  /// Raw JSON payload (preserves server-side fields not mapped above).
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Prompt request / response
// ---------------------------------------------------------------------------

class PromptRequest {
  const PromptRequest({
    this.prompt,
    this.request,
    this.reasoningEffort,
  }) : assert(
          prompt != null || request != null,
          'Either prompt or request must be provided.',
        );

  final String? prompt;
  final Map<String, dynamic>? request;
  final String? reasoningEffort;

  Map<String, dynamic> toJson() => {
        if (prompt != null) 'prompt': prompt,
        if (request != null) 'request': request,
        if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
      };
}

class PromptResponse {
  const PromptResponse({
    required this.workflowId,
    required this.status,
    required this.currentTurn,
    required this.maxTurns,
    required this.outputFormat,
    this.response,
    this.infiniteSession = true,
    this.caveman = false,
    this.tsvToolResults = false,
    this.usage,
    this.logs = const [],
    this.messages = const [],
    this.extras = const {},
  });

  factory PromptResponse.fromJson(Map<String, dynamic> json) => PromptResponse(
        workflowId: _cast<String>(json['workflow_id'], ''),
        status: _cast<String>(json['status'], ''),
        currentTurn: _int(json['current_turn']),
        maxTurns: _int(json['max_turns']),
        outputFormat: _cast<String>(json['output_format'], 'json'),
        response: _str(json['response']),
        infiniteSession: _bool(json['infinite_session'], fallback: true),
        caveman: _bool(json['caveman']),
        tsvToolResults: _bool(json['tsv_tool_results']),
        usage: json['usage'] is Map<String, dynamic>
            ? UsageStats.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        logs: (json['logs'] is List)
            ? (json['logs'] as List).whereType<Map<String, dynamic>>().map(LogEntry.fromJson).toList()
            : const [],
        messages: (json['messages'] is List)
            ? (json['messages'] as List).whereType<Map<String, dynamic>>().map(Message.fromJson).toList()
            : const [],
        extras: json,
      );

  final String workflowId;
  final String status;
  final int currentTurn;
  final int maxTurns;
  final String? response;
  final String outputFormat;
  final bool infiniteSession;
  final bool caveman;
  final bool tsvToolResults;
  final UsageStats? usage;
  final List<LogEntry> logs;
  final List<Message> messages;
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Workflow stream event
// ---------------------------------------------------------------------------

class WorkflowStreamEvent {
  const WorkflowStreamEvent({
    required this.type,
    this.id,
    this.data,
    this.timestamp,
    this.extras = const {},
  });

  factory WorkflowStreamEvent.fromJson(Map<String, dynamic> json) =>
      WorkflowStreamEvent(
        type: _cast<String>(json['type'], ''),
        id: json['id'],
        data: json['data'],
        timestamp: json['timestamp'],
        extras: json,
      );

  final String type;
  final Object? id;
  final Object? data;
  final Object? timestamp;
  final Map<String, dynamic> extras;

  @override
  String toString() => 'WorkflowStreamEvent(id: $id, type: $type)';
}

// ---------------------------------------------------------------------------
// Task execution
// ---------------------------------------------------------------------------

class TodoItem {
  const TodoItem({required this.id, required this.title, required this.status});

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'],
        title: _cast<String>(json['title'], ''),
        status: _cast<String>(json['status'], ''),
      );

  final Object? id; // int or String depending on server
  final String title;
  final String status;
}

class TaskProgress {
  const TaskProgress({
    this.todos = const [],
    this.currentStep,
    this.percentComplete = 0.0,
  });

  factory TaskProgress.fromJson(Map<String, dynamic> json) => TaskProgress(
        todos: (json['todos'] is List)
            ? (json['todos'] as List).whereType<Map<String, dynamic>>().map(TodoItem.fromJson).toList()
            : const [],
        currentStep: json['current_step'],
        percentComplete: _double(json['percent_complete']),
      );

  final List<TodoItem> todos;
  final Object? currentStep;
  final double percentComplete;
}

class TaskExecution {
  const TaskExecution({
    required this.id,
    required this.workflowId,
    required this.prompt,
    required this.status,
    required this.toolCalls,
    required this.createdAt,
    this.workflowTitle,
    this.agentName,
    this.celeryTaskId,
    this.worker,
    this.model,
    this.reasoningEffort,
    this.response,
    this.progress,
    this.logs = const [],
    this.messages = const [],
    this.usage,
    this.startedAt,
    this.finishedAt,
    this.elapsedSeconds,
    this.extras = const {},
  });

  factory TaskExecution.fromJson(Map<String, dynamic> json) => TaskExecution(
        id: _cast<String>(json['id'], ''),
        workflowId: _cast<String>(json['workflow_id'], ''),
        prompt: _cast<String>(json['prompt'], ''),
        status: _cast<String>(json['status'], ''),
        toolCalls: _int(json['tool_calls']),
        createdAt: _cast<String>(json['created_at'], ''),
        workflowTitle: _str(json['workflow_title']),
        agentName: _str(json['agent_name']),
        celeryTaskId: _str(json['celery_task_id']),
        worker: _str(json['worker']),
        model: _str(json['model']),
        reasoningEffort: _str(json['reasoning_effort']),
        response: _str(json['response']),
        progress: json['progress'] is Map<String, dynamic>
            ? TaskProgress.fromJson(json['progress'] as Map<String, dynamic>)
            : null,
        logs: (json['logs'] is List)
            ? (json['logs'] as List).whereType<Map<String, dynamic>>().map(LogEntry.fromJson).toList()
            : const [],
        messages: (json['messages'] is List)
            ? (json['messages'] as List).whereType<Map<String, dynamic>>().map(Message.fromJson).toList()
            : const [],
        usage: json['usage'] is Map<String, dynamic>
            ? UsageStats.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        startedAt: _str(json['started_at']),
        finishedAt: _str(json['finished_at']),
        elapsedSeconds: json['elapsed_seconds'] is num
            ? (json['elapsed_seconds'] as num).toDouble()
            : null,
        extras: json,
      );

  final String id;
  final String workflowId;
  final String? workflowTitle;
  final String? agentName;
  final String prompt;
  final String status;
  final String? celeryTaskId;
  final String? worker;
  final String? model;
  final String? reasoningEffort;
  final int toolCalls;
  final String? response;
  final TaskProgress? progress;
  final List<LogEntry> logs;
  final List<Message> messages;
  final UsageStats? usage;
  final String? startedAt;
  final String? finishedAt;
  final double? elapsedSeconds;
  final String createdAt;
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Knowledge item
// ---------------------------------------------------------------------------

class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.contentType,
    required this.createdAt,
    required this.updatedAt,
    this.textContent,
    this.fileId,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.tags = const [],
    this.metadata = const {},
    this.extras = const {},
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) => KnowledgeItem(
        id: _cast<String>(json['id'], ''),
        sourceId: _cast<String>(json['source_id'], ''),
        name: _cast<String>(json['name'], ''),
        contentType: _cast<String>(json['content_type'], 'text'),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        textContent: _str(json['text_content']),
        fileId: _str(json['file_id']),
        fileName: _str(json['file_name']),
        fileSize: json['file_size'] is int ? json['file_size'] as int : null,
        mimeType: _str(json['mime_type']),
        tags: _strList(json['tags']),
        metadata: json['metadata'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>)
            : const {},
        extras: json,
      );

  final String id;
  final String sourceId;
  final String name;
  final String contentType;
  final String? textContent;
  final String? fileId;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> extras;
}

class DownloadedContent {
  const DownloadedContent({
    required this.bytes,
    this.contentType,
    this.filename,
  });

  /// Raw bytes of the downloaded file.
  final List<int> bytes;

  /// MIME type from the `Content-Type` header, if present.
  final String? contentType;

  /// Filename parsed from the `Content-Disposition` header, if present.
  final String? filename;
}

// ---------------------------------------------------------------------------
// Detail response (generic server message)
// ---------------------------------------------------------------------------

class DetailResponse {
  const DetailResponse({required this.detail, this.extras = const {}});

  factory DetailResponse.fromJson(Map<String, dynamic> json) =>
      DetailResponse(detail: _cast<String>(json['detail'], ''), extras: json);

  final String detail;
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Guardrails
// ---------------------------------------------------------------------------

class PromptGuardrailConfig {
  const PromptGuardrailConfig({
    this.forbiddenPatterns = const [],
    this.requiredPatterns = const [],
    this.maxLength,
    this.minLength,
  });

  factory PromptGuardrailConfig.fromJson(Map<String, dynamic> json) =>
      PromptGuardrailConfig(
        forbiddenPatterns: _strList(json['forbidden_patterns']),
        requiredPatterns: _strList(json['required_patterns']),
        maxLength: json['max_length'] != null ? _int(json['max_length']) : null,
        minLength: json['min_length'] != null ? _int(json['min_length']) : null,
      );

  final List<String> forbiddenPatterns;
  final List<String> requiredPatterns;
  final int? maxLength;
  final int? minLength;

  Map<String, dynamic> toJson() => {
        'forbidden_patterns': forbiddenPatterns,
        'required_patterns': requiredPatterns,
        if (maxLength != null) 'max_length': maxLength,
        if (minLength != null) 'min_length': minLength,
      };
}

class OutputGuardrailConfig {
  const OutputGuardrailConfig({
    this.forbiddenPatterns = const [],
    this.requiredPatterns = const [],
    this.maxLength,
    this.piiDetection = false,
    this.mustBeValidJson = false,
  });

  factory OutputGuardrailConfig.fromJson(Map<String, dynamic> json) =>
      OutputGuardrailConfig(
        forbiddenPatterns: _strList(json['forbidden_patterns']),
        requiredPatterns: _strList(json['required_patterns']),
        maxLength: json['max_length'] != null ? _int(json['max_length']) : null,
        piiDetection: _bool(json['pii_detection']),
        mustBeValidJson: _bool(json['must_be_valid_json']),
      );

  final List<String> forbiddenPatterns;
  final List<String> requiredPatterns;
  final int? maxLength;
  final bool piiDetection;
  final bool mustBeValidJson;

  Map<String, dynamic> toJson() => {
        'forbidden_patterns': forbiddenPatterns,
        'required_patterns': requiredPatterns,
        if (maxLength != null) 'max_length': maxLength,
        'pii_detection': piiDetection,
        'must_be_valid_json': mustBeValidJson,
      };
}

class GuardrailCreate {
  const GuardrailCreate({
    required this.name,
    required this.guardrailType,
    this.description = '',
    this.tags = const [],
    this.enabled = true,
    this.promptConfig,
    this.outputConfig,
  });

  final String name;
  final String description;
  final String guardrailType;
  final List<String> tags;
  final bool enabled;
  final PromptGuardrailConfig? promptConfig;
  final OutputGuardrailConfig? outputConfig;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'guardrail_type': guardrailType,
        'tags': tags,
        'enabled': enabled,
        if (promptConfig != null) 'prompt_config': promptConfig!.toJson(),
        if (outputConfig != null) 'output_config': outputConfig!.toJson(),
      };
}

class GuardrailUpdate {
  const GuardrailUpdate({
    this.name,
    this.description,
    this.guardrailType,
    this.tags,
    this.enabled,
    this.promptConfig,
    this.outputConfig,
  });

  final String? name;
  final String? description;
  final String? guardrailType;
  final List<String>? tags;
  final bool? enabled;
  final PromptGuardrailConfig? promptConfig;
  final OutputGuardrailConfig? outputConfig;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (guardrailType != null) 'guardrail_type': guardrailType,
        if (tags != null) 'tags': tags,
        if (enabled != null) 'enabled': enabled,
        if (promptConfig != null) 'prompt_config': promptConfig!.toJson(),
        if (outputConfig != null) 'output_config': outputConfig!.toJson(),
      };
}

class Guardrail {
  const Guardrail({
    required this.id,
    required this.name,
    required this.guardrailType,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.tags = const [],
    this.enabled = true,
    this.promptConfig,
    this.outputConfig,
    this.extras = const {},
  });

  factory Guardrail.fromJson(Map<String, dynamic> json) => Guardrail(
        id: _cast<String>(json['id'], ''),
        name: _cast<String>(json['name'], ''),
        guardrailType: _cast<String>(json['guardrail_type'], ''),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        description: _cast<String>(json['description'], ''),
        tags: _strList(json['tags']),
        enabled: _bool(json['enabled'], fallback: true),
        promptConfig: json['prompt_config'] is Map<String, dynamic>
            ? PromptGuardrailConfig.fromJson(json['prompt_config'] as Map<String, dynamic>)
            : null,
        outputConfig: json['output_config'] is Map<String, dynamic>
            ? OutputGuardrailConfig.fromJson(json['output_config'] as Map<String, dynamic>)
            : null,
        extras: json,
      );

  final String id;
  final String name;
  final String description;
  final String guardrailType;
  final List<String> tags;
  final bool enabled;
  final PromptGuardrailConfig? promptConfig;
  final OutputGuardrailConfig? outputConfig;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Memories
// ---------------------------------------------------------------------------

class MemoryCreate {
  const MemoryCreate({
    required this.agentId,
    required this.scope,
    required this.key,
    required this.value,
    this.metadata = const {},
    this.ttl,
  });

  final String agentId;
  final String scope;
  final String key;
  final String value;
  final Map<String, dynamic> metadata;
  final String? ttl;

  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        'scope': scope,
        'key': key,
        'value': value,
        'metadata': metadata,
        if (ttl != null) 'ttl': ttl,
      };
}

class MemoryUpdate {
  const MemoryUpdate({
    this.scope,
    this.key,
    this.value,
    this.metadata,
    this.ttl,
  });

  final String? scope;
  final String? key;
  final String? value;
  final Map<String, dynamic>? metadata;
  final String? ttl;

  Map<String, dynamic> toJson() => {
        if (scope != null) 'scope': scope,
        if (key != null) 'key': key,
        if (value != null) 'value': value,
        if (metadata != null) 'metadata': metadata,
        if (ttl != null) 'ttl': ttl,
      };
}

class Memory {
  const Memory({
    required this.id,
    required this.agentId,
    required this.scope,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
    this.ttl,
    this.extras = const {},
  });

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        id: _cast<String>(json['id'], ''),
        agentId: _cast<String>(json['agent_id'], ''),
        scope: _cast<String>(json['scope'], ''),
        key: _cast<String>(json['key'], ''),
        value: _cast<String>(json['value'], ''),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        metadata: json['metadata'] is Map<String, dynamic>
            ? json['metadata'] as Map<String, dynamic>
            : const {},
        ttl: _str(json['ttl']),
        extras: json,
      );

  final String id;
  final String agentId;
  final String scope;
  final String key;
  final String value;
  final Map<String, dynamic> metadata;
  final String? ttl;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> extras;
}

class MemorySearchRequest {
  const MemorySearchRequest({
    required this.agentId,
    required this.query,
    this.scope,
    this.limit = 10,
  });

  final String agentId;
  final String query;
  final String? scope;
  final int limit;

  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        'query': query,
        if (scope != null) 'scope': scope,
        'limit': limit,
      };
}

// ---------------------------------------------------------------------------
// Scheduled Agents
// ---------------------------------------------------------------------------

class ScheduledAgentCreate {
  const ScheduledAgentCreate({
    required this.name,
    required this.workflowId,
    required this.prompt,
    required this.intervalValue,
    required this.startAt,
    this.intervalUnit = 'hours',
    this.endAt,
  });

  final String name;
  final String workflowId;
  final String prompt;
  final int intervalValue;
  final String intervalUnit;
  final String startAt;
  final String? endAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'workflow_id': workflowId,
        'prompt': prompt,
        'interval_value': intervalValue,
        'interval_unit': intervalUnit,
        'start_at': startAt,
        if (endAt != null) 'end_at': endAt,
      };
}

class ScheduledAgentUpdate {
  const ScheduledAgentUpdate({
    this.name,
    this.prompt,
    this.intervalValue,
    this.intervalUnit,
    this.startAt,
    this.endAt,
  });

  final String? name;
  final String? prompt;
  final int? intervalValue;
  final String? intervalUnit;
  final String? startAt;
  final String? endAt;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (prompt != null) 'prompt': prompt,
        if (intervalValue != null) 'interval_value': intervalValue,
        if (intervalUnit != null) 'interval_unit': intervalUnit,
        if (startAt != null) 'start_at': startAt,
        if (endAt != null) 'end_at': endAt,
      };
}

class ScheduledAgent {
  const ScheduledAgent({
    required this.id,
    required this.name,
    required this.workflowId,
    required this.prompt,
    required this.intervalValue,
    required this.intervalUnit,
    required this.startAt,
    required this.createdAt,
    required this.updatedAt,
    this.endAt,
    this.enabled = true,
    this.lastRunAt,
    this.nextRunAt,
    this.extras = const {},
  });

  factory ScheduledAgent.fromJson(Map<String, dynamic> json) => ScheduledAgent(
        id: _cast<String>(json['id'], ''),
        name: _cast<String>(json['name'], ''),
        workflowId: _cast<String>(json['workflow_id'], ''),
        prompt: _cast<String>(json['prompt'], ''),
        intervalValue: _int(json['interval_value']),
        intervalUnit: _cast<String>(json['interval_unit'], 'hours'),
        startAt: _cast<String>(json['start_at'], ''),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        endAt: _str(json['end_at']),
        enabled: _bool(json['enabled'], fallback: true),
        lastRunAt: _str(json['last_run_at']),
        nextRunAt: _str(json['next_run_at']),
        extras: json,
      );

  final String id;
  final String name;
  final String workflowId;
  final String prompt;
  final int intervalValue;
  final String intervalUnit;
  final String startAt;
  final String? endAt;
  final bool enabled;
  final String? lastRunAt;
  final String? nextRunAt;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Custom Tools
// ---------------------------------------------------------------------------

class CustomToolCreate {
  const CustomToolCreate({
    required this.name,
    required this.sourceCode,
    this.description = '',
    this.parametersSchema = const {},
    this.envConfig = const {},
    this.tags = const [],
    this.isEnabled = true,
  });

  final String name;
  final String description;
  final String sourceCode;
  final Map<String, dynamic> parametersSchema;
  final Map<String, String> envConfig;
  final List<String> tags;
  final bool isEnabled;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'source_code': sourceCode,
        'parameters_schema': parametersSchema,
        'env_config': envConfig,
        'tags': tags,
        'is_enabled': isEnabled,
      };
}

class CustomToolUpdate {
  const CustomToolUpdate({
    this.name,
    this.description,
    this.sourceCode,
    this.parametersSchema,
    this.envConfig,
    this.tags,
    this.isEnabled,
  });

  final String? name;
  final String? description;
  final String? sourceCode;
  final Map<String, dynamic>? parametersSchema;
  final Map<String, String>? envConfig;
  final List<String>? tags;
  final bool? isEnabled;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (sourceCode != null) 'source_code': sourceCode,
        if (parametersSchema != null) 'parameters_schema': parametersSchema,
        if (envConfig != null) 'env_config': envConfig,
        if (tags != null) 'tags': tags,
        if (isEnabled != null) 'is_enabled': isEnabled,
      };
}

class CustomTool {
  const CustomTool({
    required this.id,
    required this.name,
    required this.sourceCode,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.parametersSchema = const {},
    this.envConfig = const {},
    this.tags = const [],
    this.isEnabled = true,
    this.isPlugin = false,
    this.extras = const {},
  });

  factory CustomTool.fromJson(Map<String, dynamic> json) => CustomTool(
        id: _cast<String>(json['id'], ''),
        name: _cast<String>(json['name'], ''),
        sourceCode: _cast<String>(json['source_code'], ''),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        description: _cast<String>(json['description'], ''),
        parametersSchema: json['parameters_schema'] is Map<String, dynamic>
            ? json['parameters_schema'] as Map<String, dynamic>
            : const {},
        envConfig: json['env_config'] is Map
            ? Map<String, String>.from(json['env_config'] as Map)
            : const {},
        tags: _strList(json['tags']),
        isEnabled: _bool(json['is_enabled'], fallback: true),
        isPlugin: _bool(json['is_plugin']),
        extras: json,
      );

  final String id;
  final String name;
  final String description;
  final String sourceCode;
  final Map<String, dynamic> parametersSchema;
  final Map<String, String> envConfig;
  final List<String> tags;
  final bool isEnabled;
  final bool isPlugin;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> extras;
}

class CustomToolRunRequest {
  const CustomToolRunRequest({this.arguments = const {}});

  final Map<String, dynamic> arguments;

  Map<String, dynamic> toJson() => {'arguments': arguments};
}

class CustomToolRunResponse {
  const CustomToolRunResponse({
    required this.toolName,
    required this.success,
    this.result,
    this.error,
    this.extras = const {},
  });

  factory CustomToolRunResponse.fromJson(Map<String, dynamic> json) =>
      CustomToolRunResponse(
        toolName: _cast<String>(json['tool_name'], ''),
        success: _bool(json['success']),
        result: json['result'],
        error: _str(json['error']),
        extras: json,
      );

  final String toolName;
  final dynamic result;
  final bool success;
  final String? error;
  final Map<String, dynamic> extras;
}

class CustomToolValidateRequest {
  const CustomToolValidateRequest({required this.sourceCode, required this.name});

  final String sourceCode;
  final String name;

  Map<String, dynamic> toJson() => {'source_code': sourceCode, 'name': name};
}

class CustomToolValidateResponse {
  const CustomToolValidateResponse({
    required this.valid,
    this.inferredSchema,
    this.error,
    this.extras = const {},
  });

  factory CustomToolValidateResponse.fromJson(Map<String, dynamic> json) =>
      CustomToolValidateResponse(
        valid: _bool(json['valid']),
        inferredSchema: json['inferred_schema'] is Map<String, dynamic>
            ? json['inferred_schema'] as Map<String, dynamic>
            : null,
        error: _str(json['error']),
        extras: json,
      );

  final bool valid;
  final Map<String, dynamic>? inferredSchema;
  final String? error;
  final Map<String, dynamic> extras;
}

class EnvVarEntry {
  const EnvVarEntry({
    required this.envVar,
    required this.template,
    this.currentToken,
  });

  factory EnvVarEntry.fromJson(Map<String, dynamic> json) => EnvVarEntry(
        envVar: _cast<String>(json['env_var'], ''),
        template: _cast<String>(json['template'], ''),
        currentToken: _str(json['current_token']),
      );

  final String envVar;
  final String? currentToken;
  final String template;
}

class EnvMappingTokenRef {
  const EnvMappingTokenRef({
    required this.id,
    required this.name,
    required this.maskedValue,
    this.description = '',
  });

  factory EnvMappingTokenRef.fromJson(Map<String, dynamic> json) =>
      EnvMappingTokenRef(
        id: _cast<String>(json['id'], ''),
        name: _cast<String>(json['name'], ''),
        maskedValue: _cast<String>(json['masked_value'], ''),
        description: _cast<String>(json['description'], ''),
      );

  final String id;
  final String name;
  final String description;
  final String maskedValue;
}

class EnvMappingResponse {
  const EnvMappingResponse({
    required this.toolId,
    required this.toolName,
    this.envVars = const [],
    this.availableTokens = const [],
    this.extras = const {},
  });

  factory EnvMappingResponse.fromJson(Map<String, dynamic> json) =>
      EnvMappingResponse(
        toolId: _cast<String>(json['tool_id'], ''),
        toolName: _cast<String>(json['tool_name'], ''),
        envVars: (json['env_vars'] is List)
            ? (json['env_vars'] as List)
                .whereType<Map<String, dynamic>>()
                .map(EnvVarEntry.fromJson)
                .toList()
            : const [],
        availableTokens: (json['available_tokens'] is List)
            ? (json['available_tokens'] as List)
                .whereType<Map<String, dynamic>>()
                .map(EnvMappingTokenRef.fromJson)
                .toList()
            : const [],
        extras: json,
      );

  final String toolId;
  final String toolName;
  final List<EnvVarEntry> envVars;
  final List<EnvMappingTokenRef> availableTokens;
  final Map<String, dynamic> extras;
}

class EnvMappingUpdate {
  const EnvMappingUpdate({this.envVarMapping = const {}});

  final Map<String, String> envVarMapping;

  Map<String, dynamic> toJson() => {'env_var_mapping': envVarMapping};
}

// ---------------------------------------------------------------------------
// Chat
// ---------------------------------------------------------------------------

class ChatRequest {
  const ChatRequest({required this.message, this.sessionId});

  final String message;
  final String? sessionId;

  Map<String, dynamic> toJson() => {
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
      };
}

class ChatMessageRecord {
  const ChatMessageRecord({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.usage,
    this.extras = const {},
  });

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) =>
      ChatMessageRecord(
        id: _cast<String>(json['id'], ''),
        role: _cast<String>(json['role'], ''),
        content: _cast<String>(json['content'], ''),
        createdAt: _cast<String>(json['created_at'], ''),
        usage: json['usage'] is Map<String, dynamic>
            ? json['usage'] as Map<String, dynamic>
            : null,
        extras: json,
      );

  final String id;
  final String role;
  final String content;
  final Map<String, dynamic>? usage;
  final String createdAt;
  final Map<String, dynamic> extras;
}

class ChatSessionResponse {
  const ChatSessionResponse({
    required this.id,
    required this.agentId,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.messageCount = 0,
    this.extras = const {},
  });

  factory ChatSessionResponse.fromJson(Map<String, dynamic> json) =>
      ChatSessionResponse(
        id: _cast<String>(json['id'], ''),
        agentId: _cast<String>(json['agent_id'], ''),
        createdAt: _cast<String>(json['created_at'], ''),
        updatedAt: _cast<String>(json['updated_at'], ''),
        title: _str(json['title']),
        messageCount: _int(json['message_count']),
        extras: json,
      );

  final String id;
  final String agentId;
  final String? title;
  final int messageCount;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> extras;
}

class ChatSessionDetail extends ChatSessionResponse {
  const ChatSessionDetail({
    required super.id,
    required super.agentId,
    required super.createdAt,
    required super.updatedAt,
    super.title,
    super.messageCount,
    this.messages = const [],
    super.extras,
  });

  factory ChatSessionDetail.fromJson(Map<String, dynamic> json) {
    final base = ChatSessionResponse.fromJson(json);
    return ChatSessionDetail(
      id: base.id,
      agentId: base.agentId,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      title: base.title,
      messageCount: base.messageCount,
      messages: (json['messages'] is List)
          ? (json['messages'] as List)
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageRecord.fromJson)
              .toList()
          : const [],
      extras: json,
    );
  }

  final List<ChatMessageRecord> messages;
}

class ChatStartRequest {
  const ChatStartRequest({required this.agentId});

  final String agentId;

  Map<String, dynamic> toJson() => {'agent_id': agentId};
}

class ChatStartResponse {
  const ChatStartResponse({
    required this.workflowId,
    required this.agentName,
    required this.agentId,
    this.extras = const {},
  });

  factory ChatStartResponse.fromJson(Map<String, dynamic> json) =>
      ChatStartResponse(
        workflowId: _cast<String>(json['workflow_id'], ''),
        agentName: _cast<String>(json['agent_name'], ''),
        agentId: _cast<String>(json['agent_id'], ''),
        extras: json,
      );

  final String workflowId;
  final String agentName;
  final String agentId;
  final Map<String, dynamic> extras;
}

// ---------------------------------------------------------------------------
// Full export / import bundle
// ---------------------------------------------------------------------------

class FullExportBundle {
  const FullExportBundle({
    this.version = '1.0',
    this.exportedAt,
    this.resourceType = 'full',
    this.skills = const [],
    this.agents = const [],
    this.workflows = const [],
    this.knowledgeSources = const [],
    this.extras = const {},
  });

  factory FullExportBundle.fromJson(Map<String, dynamic> json) =>
      FullExportBundle(
        version: _cast<String>(json['version'], '1.0'),
        exportedAt: _str(json['exported_at']),
        resourceType: _cast<String>(json['resource_type'], 'full'),
        skills: json['skills'] is List
            ? List<Map<String, dynamic>>.from(
                (json['skills'] as List).whereType<Map<String, dynamic>>())
            : const [],
        agents: json['agents'] is List
            ? List<Map<String, dynamic>>.from(
                (json['agents'] as List).whereType<Map<String, dynamic>>())
            : const [],
        workflows: json['workflows'] is List
            ? List<Map<String, dynamic>>.from(
                (json['workflows'] as List).whereType<Map<String, dynamic>>())
            : const [],
        knowledgeSources: json['knowledge_sources'] is List
            ? List<Map<String, dynamic>>.from(
                (json['knowledge_sources'] as List).whereType<Map<String, dynamic>>())
            : const [],
        extras: json,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        if (exportedAt != null) 'exported_at': exportedAt,
        'resource_type': resourceType,
        'skills': skills,
        'agents': agents,
        'workflows': workflows,
        'knowledge_sources': knowledgeSources,
      };

  final String version;
  final String? exportedAt;
  final String resourceType;
  final List<Map<String, dynamic>> skills;
  final List<Map<String, dynamic>> agents;
  final List<Map<String, dynamic>> workflows;
  final List<Map<String, dynamic>> knowledgeSources;
  final Map<String, dynamic> extras;
}

class BundleImportResult {
  const BundleImportResult({
    this.skills,
    this.agents,
    this.workflows,
    this.knowledgeSources,
    this.extras = const {},
  });

  factory BundleImportResult.fromJson(Map<String, dynamic> json) =>
      BundleImportResult(
        skills: json['skills'] is Map<String, dynamic>
            ? ImportResult.fromJson(json['skills'] as Map<String, dynamic>)
            : null,
        agents: json['agents'] is Map<String, dynamic>
            ? ImportResult.fromJson(json['agents'] as Map<String, dynamic>)
            : null,
        workflows: json['workflows'] is Map<String, dynamic>
            ? ImportResult.fromJson(json['workflows'] as Map<String, dynamic>)
            : null,
        knowledgeSources: json['knowledge_sources'] is Map<String, dynamic>
            ? ImportResult.fromJson(json['knowledge_sources'] as Map<String, dynamic>)
            : null,
        extras: json,
      );

  final ImportResult? skills;
  final ImportResult? agents;
  final ImportResult? workflows;
  final ImportResult? knowledgeSources;
  final Map<String, dynamic> extras;
}

