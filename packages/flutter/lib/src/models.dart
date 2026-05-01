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
