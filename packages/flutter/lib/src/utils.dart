/// Utility helpers used internally by the SDK.
library;

import 'dart:convert';

/// Strips a trailing `/api` suffix, returning `(baseUrl, apiBaseUrl)`.
///
/// Examples:
/// - `'https://example.com'`  → `('https://example.com', 'https://example.com/api')`
/// - `'https://example.com/api'` → `('https://example.com', 'https://example.com/api')`
/// - `'https://example.com/'` → `('https://example.com', 'https://example.com/api')`
(String baseUrl, String apiBaseUrl) normalizeBaseUrls(String baseUrl) {
  var value = baseUrl.trimRight();
  while (value.endsWith('/')) {
    value = value.substring(0, value.length - 1);
  }
  if (value.isEmpty) {
    throw ArgumentError('baseUrl must not be empty');
  }
  if (value.endsWith('/api')) {
    final base = value.substring(0, value.length - 4);
    return (base, value);
  }
  return (value, '$value/api');
}

/// Joins a [base] URL with a [path], ensuring exactly one `/` between them.
String joinUrl(String base, String path) {
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final p = path.startsWith('/') ? path.substring(1) : path;
  return '$b/$p';
}

/// Returns a copy of [map] with all `null` values removed.
Map<String, dynamic> removeNulls(Map<String, dynamic> map) {
  return Map.fromEntries(
    map.entries.where((e) => e.value != null),
  );
}

/// Encodes [value] to a JSON string.
String encodeJson(Object? value) => json.encode(value);

/// Attempts to decode a response body as JSON; falls back to the raw string.
Object? tryDecodeJson(String body) {
  if (body.isEmpty) return null;
  try {
    return json.decode(body);
  } catch (_) {
    return body;
  }
}

/// Extracts the `filename` value from a `Content-Disposition` header.
///
/// Returns `null` if the header is absent or contains no filename.
String? parseContentDispositionFilename(String? header) {
  if (header == null || header.isEmpty) return null;
  final re = RegExp(r'filename="?([^";]+)"?');
  final match = re.firstMatch(header);
  return match?.group(1);
}
