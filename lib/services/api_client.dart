import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'EH_ANGOLA_API_URL',
    defaultValue: 'https://api-ehangola-production.up.railway.app/api',
  );

  static const _tokenKey = 'eh_angola_auth_token';

  static void Function()? onUnauthorized;

  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<dynamic> get(String path, {Map<String, String?> query = const {}, bool authenticated = false}) {
    return _send('GET', path, query: query, authenticated: authenticated);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool authenticated = false}) {
    return _send('POST', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool authenticated = false}) {
    return _send('PUT', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> delete(String path, {bool authenticated = false}) {
    return _send('DELETE', path, authenticated: authenticated);
  }

  Future<String> uploadImage(String filePath) async {
    final currentToken = await token;
    if (currentToken == null || currentToken.isEmpty) {
      throw const ApiException('Inicie sessao para continuar.', statusCode: 401);
    }
    final uri = Uri.parse('$baseUrl/upload/image');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $currentToken'
      ..headers['Accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 60));
    } on SocketException {
      throw const ApiException('Nao foi possivel contactar a API.');
    } on TimeoutException {
      throw const ApiException('Nao foi possivel contactar a API.');
    }

    final body = await streamed.stream.bytesToString();
    dynamic decoded;
    try {
      decoded = body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      throw const ApiException('A API devolveu uma resposta invalida.');
    }

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final url = decoded is Map ? decoded['url']?.toString() : null;
      if (url == null || url.isEmpty) throw const ApiException('URL da imagem nao devolvida.');
      return url;
    }

    if (streamed.statusCode == 401) {
      await clearToken();
      onUnauthorized?.call();
    }
    final message = decoded is Map
        ? decoded['message']?.toString() ?? 'Erro no upload da imagem.'
        : 'Erro no upload da imagem.';
    throw ApiException(message, statusCode: streamed.statusCode);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    final filteredQuery = {
      for (final entry in query.entries)
        if (entry.value != null && entry.value!.isNotEmpty) entry.key: entry.value!,
    };
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: filteredQuery.isEmpty ? null : filteredQuery);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final currentToken = await token;
      if (currentToken == null || currentToken.isEmpty) {
        throw const ApiException('Inicie sessao para continuar.', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $currentToken';
    }

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body)).timeout(const Duration(seconds: 20));
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body)).timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        default:
          throw ArgumentError('Metodo HTTP nao suportado: $method');
      }
    } on http.ClientException {
      throw const ApiException('Nao foi possivel contactar a API.');
    } on TimeoutException {
      throw const ApiException('Nao foi possivel contactar a API.');
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('A API devolveu uma resposta invalida.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    if (response.statusCode == 401) {
      await clearToken();
      onUnauthorized?.call();
    }

    String message = 'Pedido invalido. Tente novamente.';
    Map<String, dynamic>? errors;
    if (decoded is Map<String, dynamic>) {
      message = decoded['message']?.toString() ?? message;
      final rawErrors = decoded['errors'];
      if (rawErrors is Map<String, dynamic>) errors = rawErrors;
    }
    throw ApiException(message, statusCode: response.statusCode, errors: errors);
  }
}
