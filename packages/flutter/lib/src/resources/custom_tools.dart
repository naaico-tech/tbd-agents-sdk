/// Custom Tools resource — `/api/custom-tools`.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import 'base.dart';

class CustomToolsResource extends BaseResource {
  const CustomToolsResource(super.client);

  Future<List<CustomTool>> list({String? tag}) async {
    final data = await client.request(
      'GET',
      'custom-tools',
      queryParameters: tag != null ? {'tag': tag} : null,
    );
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(CustomTool.fromJson).toList();
    }
    return const [];
  }

  Future<CustomTool> get(String id) async {
    final data = await client.request('GET', 'custom-tools/$id');
    return CustomTool.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomTool> create(CustomToolCreate payload) async {
    final data = await client.request('POST', 'custom-tools', body: payload.toJson());
    return CustomTool.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomTool> update(String id, CustomToolUpdate payload) async {
    final data = await client.request('PUT', 'custom-tools/$id', body: payload.toJson());
    return CustomTool.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => client.request('DELETE', 'custom-tools/$id');

  Future<CustomToolRunResponse> run(String id, CustomToolRunRequest payload) async {
    final data = await client.request('POST', 'custom-tools/$id/run', body: payload.toJson());
    return CustomToolRunResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomToolValidateResponse> validate(CustomToolValidateRequest payload) async {
    final data = await client.request('POST', 'custom-tools/validate', body: payload.toJson());
    return CustomToolValidateResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<CustomTool> upload({
    required List<int> fileBytes,
    required String name,
    String fileName = 'tool.py',
    String description = '',
    List<String> tags = const [],
  }) async {
    final data = await client.multipartRequest(
      'custom-tools/upload',
      fields: {
        'name': name,
        'description': description,
        'tags': jsonEncode(tags),
      },
      files: [
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      ],
    );
    return CustomTool.fromJson(data as Map<String, dynamic>);
  }

  Future<EnvMappingResponse> getEnvMapping(String id) async {
    final data = await client.request('GET', 'custom-tools/$id/env-mapping');
    return EnvMappingResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<EnvMappingResponse> updateEnvMapping(String id, EnvMappingUpdate payload) async {
    final data = await client.request('PUT', 'custom-tools/$id/env-mapping', body: payload.toJson());
    return EnvMappingResponse.fromJson(data as Map<String, dynamic>);
  }
}
