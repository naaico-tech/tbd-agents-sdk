/// TBD Agents Dart/Flutter SDK.
///
/// Usage:
/// ```dart
/// import 'package:tbd_agents/tbd_agents.dart';
///
/// final client = TbdAgentsClient(
///   baseUrl: 'https://my-server.example.com',
///   token: 'my-api-token',
/// );
///
/// final health = await client.health.get();
/// print(health.status); // 'ok'
/// ```
library tbd_agents;

export 'src/client.dart';
export 'src/exceptions.dart';
export 'src/models.dart';
export 'src/sse.dart' show SseMessage, parseSseStream, iterSseMessages;
export 'src/resources/agents.dart';
export 'src/resources/base.dart' show BaseResource;
export 'src/resources/chat.dart';
export 'src/resources/collection.dart';
export 'src/resources/custom_tools.dart';
export 'src/resources/export_import.dart';
export 'src/resources/guardrails.dart';
export 'src/resources/health.dart';
export 'src/resources/knowledge_items.dart';
export 'src/resources/knowledge_sources.dart';
export 'src/resources/mcps.dart';
export 'src/resources/memories.dart';
export 'src/resources/models_resource.dart';
export 'src/resources/providers.dart';
export 'src/resources/scheduled_agents.dart';
export 'src/resources/skills.dart';
export 'src/resources/tasks.dart';
export 'src/resources/tokens.dart';
export 'src/resources/workflows.dart';
