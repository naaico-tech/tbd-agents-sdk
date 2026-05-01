/// Health resource — `/health` (outside /api).
library;

import '../models.dart';
import 'base.dart';

/// Provides access to the `/health` endpoint.
class HealthResource extends BaseResource {
  const HealthResource(super.client);

  /// `GET /health` — returns the server health status.
  Future<HealthStatus> get() async {
    final data = await client.request('GET', 'health', api: false);
    return HealthStatus.fromJson((data as Map<String, dynamic>?) ?? {});
  }
}
