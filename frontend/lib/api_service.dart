import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

String errorMessage(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}

class ApiService {
  String? token;

  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');

    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/$'), '');
    }

    return Platform.isAndroid
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  Future<dynamic> request(String method, String path, {Json? body}) async {
    final client = http.Client();

    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));

      request.headers['Content-Type'] = 'application/json';

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 20));

      final dynamic data = response.body.isEmpty
          ? null
          : jsonDecode(response.body);

      if (response.statusCode >= 400) {
        final dynamic message = data is Map
            ? data['message']
            : 'API error ${response.statusCode}';

        throw Exception(
          message is List
              ? message.join('\n')
              : message?.toString() ?? 'Something went wrong.',
        );
      }

      return data;
    } on TimeoutException {
      throw Exception('The connection timed out. Please try again.');
    } on SocketException {
      throw Exception('Unable to connect to the server.');
    } on http.ClientException {
      throw Exception('Unable to connect to the server.');
    } on FormatException {
      throw Exception('The server returned an invalid response.');
    } finally {
      client.close();
    }
  }

  Future<List<Json>> list(String path) async {
    final data = await request('GET', path);

    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> login(String email, String password) async {
    final result = await request(
      'POST',
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );

    token = result['access_token'] as String;
  }

  Future<void> register(String name, String email, String password) async {
    await request(
      'POST',
      '/auth/register',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );

    await login(email, password);
  }

  Future<Json> uploadAvatar(Uint8List bytes) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('The image must be smaller than 5 MB.');
    }

    if (token == null) {
      throw Exception('Please log in again.');
    }

    final client = http.Client();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/profile/avatar'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'profile-photo'),
      );

      // MultipartRequest จะตั้ง Content-Type พร้อม boundary ให้เอง
      final response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(const Duration(seconds: 30));

      final dynamic data = response.body.isEmpty
          ? null
          : jsonDecode(response.body);

      if (response.statusCode >= 400) {
        final dynamic message = data is Map
            ? data['message']
            : 'Unable to upload the image.';

        throw Exception(
          message is List
              ? message.join('\n')
              : message?.toString() ?? 'Unable to upload the image.',
        );
      }

      if (data is! Map) {
        throw Exception('The server returned an invalid response.');
      }

      return Map<String, dynamic>.from(data);
    } on TimeoutException {
      throw Exception('Upload timed out. Please try again.');
    } on SocketException {
      throw Exception('Unable to connect to the server.');
    } on http.ClientException {
      throw Exception('Unable to connect to the server.');
    } on FormatException {
      throw Exception('The server returned an invalid response.');
    } finally {
      client.close();
    }
  }
}
