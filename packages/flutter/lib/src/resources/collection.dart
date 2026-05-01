/// Generic CRUD collection resource for simple endpoints.
library;

import 'base.dart';

/// A generic resource that provides list / get / create / update / delete
/// operations for endpoints that follow the standard collection pattern.
///
/// Responses are returned as raw [Map<String, dynamic>] / [List] to stay
/// flexible for endpoints that are not individually typed.
class CollectionResource extends BaseResource {
  const CollectionResource(super.client, this.basePath);

  /// API path prefix, e.g. `'agents'` or `'providers'`.
  final String basePath;

  /// Lists all records at `GET /api/{basePath}`.
  Future<List<Map<String, dynamic>>> list() async {
    final data = await client.request('GET', basePath);
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  /// Fetches a single record at `GET /api/{basePath}/{id}`.
  Future<Map<String, dynamic>> get(String id) async {
    final data = await client.request('GET', '$basePath/$id');
    return (data as Map<String, dynamic>?) ?? {};
  }

  /// Creates a new record at `POST /api/{basePath}`.
  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', basePath, body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  /// Updates a record at `PUT /api/{basePath}/{id}`.
  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> payload) async {
    final data = await client.request('PUT', '$basePath/$id', body: payload);
    return (data as Map<String, dynamic>?) ?? {};
  }

  /// Deletes a record at `DELETE /api/{basePath}/{id}`.
  Future<void> delete(String id) =>
      client.request('DELETE', '$basePath/$id');
}
