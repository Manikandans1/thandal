import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_config.dart';
import 'api_exception.dart';

/// One file to upload with a multipart request (ID proof photo).
class UploadFile {
  final String field;
  final String path;
  final String filename;
  final String contentType; // e.g. image/jpeg
  const UploadFile({
    required this.field,
    required this.path,
    required this.filename,
    this.contentType = 'image/jpeg',
  });
}

/// Small JSON client for the Thandal API (Laravel + Sanctum bearer token).
/// Built on dart:io so the app needs no extra HTTP package.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// The Sanctum token of the signed-in user. null while signed out.
  String? token;

  /// Called when the server says the token is no longer valid (expired / revoked),
  /// so the app can send the user back to the login screen.
  void Function()? onUnauthorized;

  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 15);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$p');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', _uri(path, query));

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', _uri(path), body: body ?? const {});

  /// multipart/form-data (used when creating a customer / agent with an ID proof photo).
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    UploadFile? file,
  }) =>
      _send('POST', _uri(path), fields: fields, file: file);

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String>? fields,
    UploadFile? file,
  }) async {
    try {
      final req = await _http.openUrl(method, uri).timeout(ApiConfig.timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final t = token;
      if (t != null) req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $t');

      if (fields != null) {
        final boundary = '----thandal${DateTime.now().microsecondsSinceEpoch}';
        req.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
        final out = BytesBuilder();
        void put(String s) => out.add(utf8.encode(s));
        fields.forEach((k, v) {
          put('--$boundary\r\nContent-Disposition: form-data; name="$k"\r\n\r\n$v\r\n');
        });
        if (file != null) {
          put('--$boundary\r\nContent-Disposition: form-data; name="${file.field}"; '
              'filename="${file.filename}"\r\nContent-Type: ${file.contentType}\r\n\r\n');
          out.add(await File(file.path).readAsBytes());
          put('\r\n');
        }
        put('--$boundary--\r\n');
        final bytes = out.toBytes();
        req.contentLength = bytes.length;
        req.add(bytes);
      } else if (method != 'GET') {
        final bytes = utf8.encode(jsonEncode(body ?? const {}));
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
        req.contentLength = bytes.length;
        req.add(bytes);
      }

      final res = await req.close().timeout(ApiConfig.timeout);
      final raw = await res.transform(utf8.decoder).join().timeout(ApiConfig.timeout);
      return _handle(res.statusCode, raw);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException("Thandal server is taking too long to answer. Check your internet and try again.");
    } on SocketException {
      throw const ApiException("Can't reach the Thandal server. Check your internet connection and try again.");
    } on HandshakeException {
      throw const ApiException("Could not make a secure connection to the Thandal server.");
    } on HttpException {
      throw const ApiException("Can't reach the Thandal server. Check your internet connection and try again.");
    } on FormatException {
      throw const ApiException('The server sent an unexpected answer. Please try again.');
    }
  }

  dynamic _handle(int status, String text) {
    dynamic json;
    if (text.trim().isNotEmpty) {
      try {
        json = jsonDecode(text);
      } catch (_) {
        json = null;
      }
    }

    if (status >= 200 && status < 300) return json;

    if (status == 401) {
      onUnauthorized?.call();
      throw const ApiException('Your session has ended. Please log in again.', statusCode: 401);
    }

    String message = 'Something went wrong. Please try again.';
    final fieldErrors = <String, String>{};
    int? attemptsLeft;
    if (json is Map) {
      final m = json['message'];
      if (m is String && m.isNotEmpty) message = m;
      final errors = json['errors'];
      if (errors is Map) {
        errors.forEach((k, v) {
          if (v is List && v.isNotEmpty) fieldErrors[k.toString()] = v.first.toString();
        });
        if (fieldErrors.isNotEmpty) message = fieldErrors.values.first;
      }
      final a = json['attempts_left'];
      if (a is int) attemptsLeft = a;
    } else if (status >= 500) {
      message = 'The Thandal server had a problem. Please try again in a moment.';
    }
    if (status == 403 && json is! Map) message = 'You do not have access to this.';
    if (status == 404 && json is Map && (json['message'] == null || json['message'] == '')) {
      message = 'That record was not found.';
    }
    if (status == 429) message = 'Too many attempts. Please wait a minute and try again.';
    throw ApiException(message, statusCode: status, fieldErrors: fieldErrors, attemptsLeft: attemptsLeft);
  }
}
