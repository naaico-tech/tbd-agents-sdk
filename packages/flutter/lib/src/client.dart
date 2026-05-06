/// Main TBD Agents HTTP client.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'utils.dart';
import 'resources/agents.dart';
import 'resources/chat.dart';
import 'resources/custom_tools.dart';
import 'resources/export_import.dart';
import 'resources/guardrails.dart';
import 'resources/health.dart';
import 'resources/knowledge_items.dart';
import 'resources/knowledge_sources.dart';
import 'resources/mcps.dart';
import 'resources/memories.dart';
import 'resources/models_resource.dart';
import 'resources/providers.dart';
import 'resources/scheduled_agents.dart';
import 'resources/skills.dart';
import 'resources/tasks.dart';
import 'resources/tokens.dart';
import 'resources/workflows.dart';

const _kUserAgent = 'tbd-agents-dart/0.1.0';

/// Configuration for [TbdAgentsClient].
class TbdAgentsClientConfig {
  const TbdAgentsClientConfig({
    required this.baseUrl,
    this.token,
    this.timeoutMs = 30000,
    this.defaultHeaders = const {},
    this.httpClient,
  });

  /// Base URL of the TBD Agents server (e.g. `'https://example.com'`).
  ///
  /// A trailing `/api` suffix is recognized and stripped; `/api` is
  /// re-appended internally.  `/health` is always served from the root.
  final String baseUrl;

  /// Optional API token sent as `Authorization: Bearer <token>`.
  ///
  /// If `null` or blank, the `Authorization` header is **not** sent.
  /// Any `Authorization` key passed via [defaultHeaders] is also ignored.
  final String? token;

  /// Request timeout in milliseconds (default: 30 000).
  final int timeoutMs;

  /// Default headers added to every request.
  ///
  /// The `Authorization` key is silently ignored here; use [token] instead.
  final Map<String, String> defaultHeaders;

  /// Provide a custom [http.Client] implementation (e.g. for testing or
  /// to plug in a custom TLS configuration).
  ///
  /// When `null` a plain `http.Client()` is created internally.
  final http.Client? httpClient;
}

/// The TBD Agents SDK client.
///
/// Provides access to every resource surface of the TBD Agents API through
/// typed resource helpers.
///
/// ```dart
/// final client = TbdAgentsClient(
///   baseUrl: 'https://my-server.example.com',
///   token: 'my-api-token',
/// );
///
/// final workflows = await client.workflows.list();
/// ```
///
/// Always call [close] (or use a `try/finally`) when you are done with the
/// client to free underlying connections.
class TbdAgentsClient {
  TbdAgentsClient({
    required String baseUrl,
    String? token,
    int timeoutMs = 30000,
    Map<String, String> defaultHeaders = const {},
    http.Client? httpClient,
  }) : this.fromConfig(
          TbdAgentsClientConfig(
            baseUrl: baseUrl,
            token: token,
            timeoutMs: timeoutMs,
            defaultHeaders: defaultHeaders,
            httpClient: httpClient,
          ),
        );

  TbdAgentsClient.fromConfig(TbdAgentsClientConfig config) {
    final (base, api) = normalizeBaseUrls(config.baseUrl);
    _baseUrl = base;
    _apiBaseUrl = api;
    _timeoutMs = config.timeoutMs;
    _httpClient = config.httpClient ?? http.Client();
    _ownedClient = config.httpClient == null;

    // Resolve token: strip whitespace; treat blank as absent.
    final rawToken = config.token?.trim();
    _token = (rawToken != null && rawToken.isNotEmpty) ? rawToken : null;

    // Merge default headers, filtering out any caller-supplied Authorization.
    _defaultHeaders = {
      'accept': 'application/json',
      'user-agent': _kUserAgent,
      for (final e in config.defaultHeaders.entries)
        if (e.key.toLowerCase() != 'authorization') e.key: e.value,
    };

    // Attach resource helpers.
    health = HealthResource(this);
    agents = AgentsResource(this);
    chat = ChatResource(this);
    customTools = CustomToolsResource(this);
    exportImport = ExportImportResource(this);
    guardrails = GuardrailsResource(this);
    memories = MemoriesResource(this);
    scheduledAgents = ScheduledAgentsResource(this);
    skills = SkillsResource(this);
    mcps = McpsResource(this);
    knowledgeSources = KnowledgeSourcesResource(this);
    knowledgeItems = KnowledgeItemsResource(this);
    workflows = WorkflowsResource(this);
    tasks = TasksResource(this);
    providers = ProvidersResource(this);
    tokens = TokensResource(this);
    models = ModelsResource(this);
  }

  late final String _baseUrl;
  late final String _apiBaseUrl;
  late final int _timeoutMs;
  late final http.Client _httpClient;
  late final bool _ownedClient;
  late final String? _token;
  late final Map<String, String> _defaultHeaders;

  // ---------------------------------------------------------------------------
  // Resource helpers
  // ---------------------------------------------------------------------------

  late final HealthResource health;
  late final AgentsResource agents;
  late final ChatResource chat;
  late final CustomToolsResource customTools;

  /// Snake-case alias for [customTools].
  CustomToolsResource get custom_tools => customTools;

  late final ExportImportResource exportImport;

  /// Snake-case alias for [exportImport].
  ExportImportResource get export_import => exportImport;

  late final GuardrailsResource guardrails;
  late final MemoriesResource memories;
  late final ScheduledAgentsResource scheduledAgents;

  /// Snake-case alias for [scheduledAgents].
  ScheduledAgentsResource get scheduled_agents => scheduledAgents;

  late final SkillsResource skills;
  late final McpsResource mcps;
  late final KnowledgeSourcesResource knowledgeSources;

  /// Snake-case alias for [knowledgeSources].
  KnowledgeSourcesResource get knowledge_sources => knowledgeSources;

  late final KnowledgeItemsResource knowledgeItems;

  /// Snake-case alias for [knowledgeItems].
  KnowledgeItemsResource get knowledge_items => knowledgeItems;

  late final WorkflowsResource workflows;
  late final TasksResource tasks;
  late final ProvidersResource providers;
  late final TokensResource tokens;
  late final ModelsResource models;

  // ---------------------------------------------------------------------------
  // URL building
  // ---------------------------------------------------------------------------

  /// Builds a full URL for [path].
  ///
  /// When [api] is `true` the path is resolved against `{baseUrl}/api/`.
  /// When [api] is `false` the path is resolved against `{baseUrl}/`.
  String buildUrl(String path, {required bool api}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = api ? _apiBaseUrl : _baseUrl;
    return joinUrl(base, path);
  }

  // ---------------------------------------------------------------------------
  // Low-level request helpers
  // ---------------------------------------------------------------------------

  /// Headers that are sent with every request.
  Map<String, String> get _headers {
    return {
      ..._defaultHeaders,
      if (_token != null) 'authorization': 'Bearer $_token',
    };
  }

  /// Sends an HTTP request and returns the raw [http.Response].
  ///
  /// This is the **raw escape hatch** — no status-code checking is performed.
  Future<http.Response> rawRequest(
    String method,
    String path, {
    bool api = true,
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    final url = _buildUri(path, api: api, queryParameters: queryParameters);
    final mergedHeaders = {..._headers, ...?headers};

    final req = http.Request(method.toUpperCase(), url)
      ..headers.addAll(mergedHeaders);

    if (body != null) {
      if (body is String) {
        req.body = body;
      } else if (body is List<int>) {
        req.bodyBytes = Uint8List.fromList(body);
      } else if (body is Map || body is List) {
        req.body = json.encode(body);
        req.headers['content-type'] = 'application/json';
      }
    }

    return _withTimeout(_httpClient.send(req).then(http.Response.fromStream));
  }

  /// Performs an HTTP request, checks the status code, and returns the parsed
  /// body.
  ///
  /// - `204 No Content` → `null`
  /// - `application/json` content-type → parsed [Map] / [List]
  /// - anything else → raw [String]
  Future<Object?> request(
    String method,
    String path, {
    bool api = true,
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await rawRequest(
      method,
      path,
      api: api,
      headers: headers,
      body: body,
      queryParameters: queryParameters,
    );
    _throwOnError(response);
    return _parseBody(response);
  }

  /// Sends a multipart/form-data POST request.
  Future<Object?> multipartRequest(
    String path, {
    bool api = true,
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    Map<String, String>? headers,
  }) async {
    final url = _buildUri(path, api: api);
    final req = http.MultipartRequest('POST', url)
      ..headers.addAll({..._headers, ...?headers})
      ..fields.addAll(fields)
      ..files.addAll(files);

    final streamed = await _withTimeout(_httpClient.send(req));
    final response = await http.Response.fromStream(streamed);
    _throwOnError(response);
    return _parseBody(response);
  }

  /// Opens a streaming GET connection (for SSE).
  ///
  /// Returns the [http.StreamedResponse] directly so callers can consume the
  /// body as a [Stream<List<int>>].
  Future<http.StreamedResponse> streamRequest(
    String method,
    String path, {
    bool api = true,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = _buildUri(path, api: api);
    final mergedHeaders = {
      ..._headers,
      'accept': 'text/event-stream',
      ...?headers,
    };

    final req = http.Request(method.toUpperCase(), url)
      ..headers.addAll(mergedHeaders);

    if (body != null && body is Map) {
      req.body = json.encode(body);
      req.headers['content-type'] = 'application/json';
    }

    // NOTE: No timeout wrapper here — SSE connections are long-lived.
    try {
      return await _httpClient.send(req);
    } catch (e) {
      throw TransportException('Stream request failed: $e', cause: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /// Releases the underlying HTTP connection pool.
  ///
  /// Has no effect if the [http.Client] was supplied externally via
  /// [TbdAgentsClientConfig.httpClient].
  void close() {
    if (_ownedClient) _httpClient.close();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Uri _buildUri(
    String path, {
    required bool api,
    Map<String, String>? queryParameters,
  }) {
    final urlStr = buildUrl(path, api: api);
    final uri = Uri.parse(urlStr);
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParameters,
    });
  }

  Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(
      Duration(milliseconds: _timeoutMs),
      onTimeout: () => throw TransportException(
        'Request timed out after ${_timeoutMs}ms',
      ),
    );
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode < 400) return;

    Object? body;
    String message = response.reasonPhrase ?? 'HTTP ${response.statusCode}';

    try {
      final decoded = json.decode(response.body);
      body = decoded;
      if (decoded is Map && decoded.containsKey('detail')) {
        message = decoded['detail'].toString();
      } else {
        message = decoded.toString();
      }
    } catch (_) {
      body = response.body.isNotEmpty ? response.body : null;
      if (body != null) message = body.toString();
    }

    throw ApiException(message, statusCode: response.statusCode, body: body);
  }

  Object? _parseBody(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) return null;

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      return json.decode(response.body);
    }
    return response.body;
  }
}
