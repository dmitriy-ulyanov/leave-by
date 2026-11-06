import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import 'auth_json.dart';
import 'auth_repository.dart';

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository({
    required this.client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  final http.Client client;
  final Duration timeout;
  final String _baseUrl;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _post('/api/auth/login', {'email': email, 'password': password});
  }

  @override
  Future<AuthSession> register({required String name, required String email, required String password}) {
    return _post('/api/auth/register', {'name': name, 'email': email, 'password': password});
  }

  Future<AuthSession> _post(String path, Map<String, String> body) async {
    final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    }
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ApiException(
        _detail(response) ?? ApiException.http(response.statusCode).message,
        statusCode: response.statusCode,
      );
    }
    try {
      return authSessionFromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on FormatException {
      throw ApiException.malformed();
    } on TypeError {
      throw ApiException.malformed();
    }
  }

  String? _detail(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) return decoded['detail'] as String;
    } on FormatException {
      return null;
    }
    return null;
  }
}
