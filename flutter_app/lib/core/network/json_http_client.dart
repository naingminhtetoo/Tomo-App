import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/content_exception.dart';

class JsonHttpClient {
  const JsonHttpClient(this.client);
  final http.Client client;
  Future<String> get(Uri uri) async {
    final response = await client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200)
      throw ContentException(
        'Content request failed (${response.statusCode}).',
      );
    return utf8.decode(response.bodyBytes);
  }
}
