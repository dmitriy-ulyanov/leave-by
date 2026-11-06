import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/network/api_exception.dart';
import '../domain/saved_trip.dart';
import 'saved_trip_json.dart';
import 'saved_trip_repository.dart';

class RemoteSavedTripRepository implements SavedTripRepository {
  RemoteSavedTripRepository({
    required this.client,
    required String baseUrl,
    this.timeout = const Duration(seconds: 10),
    this.tokenProvider,
    this.onUnauthorized,
  }) : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

  final http.Client client;
  final Duration timeout;
  final String? Function()? tokenProvider;
  final void Function()? onUnauthorized;
  final String _baseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  String _tripPath(String id) => '/api/trips/${Uri.encodeComponent(id)}';

  Map<String, String> _headers({bool json = false}) {
    final token = tokenProvider?.call();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<SavedTrip>> getAll() async {
    final response = await _send(() => client.get(_uri('/api/trips'), headers: _headers()));
    _ensureSuccess(response);
    final decoded = _decode(response);
    if (decoded is! List) throw ApiException.malformed();
    try {
      return decoded.map((row) => savedTripFromJson(row as Map<String, dynamic>)).toList();
    } on FormatException {
      throw ApiException.malformed();
    } on TypeError {
      throw ApiException.malformed();
    }
  }

  @override
  Future<void> save(SavedTrip trip) async {
    final body = jsonEncode(savedTripToJson(trip));
    final response = await _send(
      () => client.put(_uri(_tripPath(trip.id)), headers: _headers(json: true), body: body),
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> delete(String id) async {
    final response = await _send(() => client.delete(_uri(_tripPath(id)), headers: _headers()));
    if (response.statusCode == 404) return;
    _ensureSuccess(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException.unauthorized();
    }
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ApiException.http(response.statusCode);
    }
  }

  Object? _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException.malformed();
    }
  }
}
