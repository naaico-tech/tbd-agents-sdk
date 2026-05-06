import 'package:test/test.dart';
import 'package:tbd_agents/src/utils.dart';

void main() {
  group('utils', () {
    test('normalizeBaseUrls trims trailing slashes and api suffixes', () {
      expect(
        normalizeBaseUrls('https://example.com'),
        equals(('https://example.com', 'https://example.com/api')),
      );
      expect(
        normalizeBaseUrls('https://example.com/api'),
        equals(('https://example.com', 'https://example.com/api')),
      );
      expect(
        normalizeBaseUrls('https://example.com///'),
        equals(('https://example.com', 'https://example.com/api')),
      );
    });

    test('normalizeBaseUrls rejects empty input after trimming', () {
      expect(
        () => normalizeBaseUrls('   '),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'baseUrl must not be empty',
          ),
        ),
      );
    });

    test('joinUrl ensures a single slash between base and path', () {
      expect(joinUrl('https://example.com', 'agents'),
          'https://example.com/agents');
      expect(joinUrl('https://example.com/', '/agents'),
          'https://example.com/agents');
    });

    test('removeNulls removes only null-valued entries', () {
      expect(
        removeNulls({
          'name': 'sdk',
          'count': 0,
          'enabled': false,
          'missing': null,
        }),
        equals({
          'name': 'sdk',
          'count': 0,
          'enabled': false,
        }),
      );
    });

    test('encodeJson and tryDecodeJson handle json, raw text, and empty text',
        () {
      expect(encodeJson({'status': 'ok'}), '{"status":"ok"}');
      expect(tryDecodeJson('{"status":"ok"}'), equals({'status': 'ok'}));
      expect(tryDecodeJson('plain text'), 'plain text');
      expect(tryDecodeJson(''), isNull);
    });

    test(
        'parseContentDispositionFilename extracts quoted and unquoted filenames',
        () {
      expect(
        parseContentDispositionFilename('attachment; filename="report.txt"'),
        'report.txt',
      );
      expect(
        parseContentDispositionFilename('attachment; filename=report.txt'),
        'report.txt',
      );
      expect(parseContentDispositionFilename('attachment'), isNull);
      expect(parseContentDispositionFilename(null), isNull);
    });
  });
}
