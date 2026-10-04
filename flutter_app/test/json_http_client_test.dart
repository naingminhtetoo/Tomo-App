import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomo/core/errors/content_exception.dart';
import 'package:tomo/core/network/json_http_client.dart';

void main() {
  test(
    'remote response preserves UTF-8 Japanese independently of response headers',
    () async {
      final client = MockClient(
        (_) async => http.Response.bytes(utf8.encode('{"word":"禁止"}'), 200),
      );
      addTearDown(client.close);
      expect(
        await JsonHttpClient(
          client,
        ).get(Uri.parse('https://example.com/n2.json')),
        '{"word":"禁止"}',
      );
    },
  );
  test('HTTP failure does not become usable content', () async {
    final client = MockClient((_) async => http.Response('not found', 404));
    addTearDown(client.close);
    await expectLater(
      JsonHttpClient(client).get(Uri.parse('https://example.com/n2.json')),
      throwsA(isA<ContentException>()),
    );
  });
}
