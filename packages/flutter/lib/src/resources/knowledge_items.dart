/// Knowledge items resource — `/api/knowledge-items`.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import '../utils.dart';
import 'base.dart';

class KnowledgeItemsResource extends BaseResource {
  const KnowledgeItemsResource(super.client);

  Future<List<KnowledgeItem>> list({
    String? sourceId,
    List<String>? tags,
    String? contentType,
  }) async {
    final params = <String, String>{
      if (sourceId != null) 'source_id': sourceId,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      if (contentType != null) 'content_type': contentType,
    };
    final data = await client.request(
      'GET',
      'knowledge-items',
      queryParameters: params.isEmpty ? null : params,
    );
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(KnowledgeItem.fromJson).toList();
    }
    return const [];
  }

  Future<KnowledgeItem> get(String id) async {
    final data = await client.request('GET', 'knowledge-items/$id');
    return KnowledgeItem.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<KnowledgeItem> create(Map<String, dynamic> payload) async {
    final data = await client.request('POST', 'knowledge-items', body: payload);
    return KnowledgeItem.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<KnowledgeItem> update(String id, Map<String, dynamic> payload) async {
    final data =
        await client.request('PUT', 'knowledge-items/$id', body: payload);
    return KnowledgeItem.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  Future<void> delete(String id) =>
      client.request('DELETE', 'knowledge-items/$id');

  /// `POST /api/knowledge-items/query` — semantic / tag-based query.
  Future<Map<String, dynamic>> query({
    required List<String> tags,
    int limit = 10,
  }) async {
    final data = await client.request(
      'POST',
      'knowledge-items/query',
      body: {'tags': tags, 'limit': limit},
    );
    return (data as Map<String, dynamic>?) ?? {};
  }

  /// `POST /api/knowledge-items/upload` — multipart file upload.
  ///
  /// [bytes] is the raw file content.  [filename] defaults to `'upload.bin'`.
  Future<KnowledgeItem> upload({
    required String sourceId,
    required List<int> bytes,
    String filename = 'upload.bin',
    String contentType = 'application/octet-stream',
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    final file = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: http.MediaType.parse(contentType),
    );

    final data = await client.multipartRequest(
      'knowledge-items/upload',
      fields: {
        'source_id': sourceId,
        'tags': json.encode(tags),
        'metadata': json.encode(metadata),
      },
      files: [file],
    );
    return KnowledgeItem.fromJson((data as Map<String, dynamic>?) ?? {});
  }

  /// `GET /api/knowledge-items/{id}/content` — binary download.
  Future<DownloadedContent> download(String id) async {
    final response = await client.rawRequest('GET', 'knowledge-items/$id/content');
    if (response.statusCode >= 400) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }
    return DownloadedContent(
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'],
      filename: parseContentDispositionFilename(
        response.headers['content-disposition'],
      ),
    );
  }
}
