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
    required http.Client client,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = client,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _timeout = timeout;

  static const Map<String, String> _jsonHeaders = {'Content-Type': 'application/json'};

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  String _tripPath(String id) => '/api/trips/${Uri.encodeComponent(id)}';

  @override
  Future<List<SavedTrip>> getAll() async {
    final response = await _send(() => _client.get(_uri('/api/trips')));
    _ensureSuccess(response);
    final decoded = _decode(response.body);
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
    final response = await _send(() => _client.put(_uri(_tripPath(trip.id)), headers: _jsonHeaders, body: body));
    _ensureSuccess(response);
  }

  @override
  Future<void> delete(String id) async {
    final response = await _send(() => _client.delete(_uri(_tripPath(id))));
    if (response.statusCode == 404) return;
    _ensureSuccess(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ApiException.http(response.statusCode);
    }
  }

  Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw ApiException.malformed();
    }
  }
}
