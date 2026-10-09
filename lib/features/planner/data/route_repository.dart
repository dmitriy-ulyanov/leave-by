import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/route_option.dart';
import '../domain/trip_request.dart';

abstract class RouteRepository {
  Future<List<String>> loadPlaces();

  Future<List<RouteOption>> findOptions(TripRequest request);
}

class AssetRouteRepository implements RouteRepository {
  AssetRouteRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String _path = 'assets/data/routes.json';

  final AssetBundle _bundle;

  Future<List<Map<String, dynamic>>> _loadRows() async {
    final raw = await _bundle.loadString(_path);
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<String>> loadPlaces() async {
    final rows = await _loadRows();
    final places = <String>{};
    for (final row in rows) {
      places.add(row['origin'] as String);
      places.add(row['destination'] as String);
    }
    return places.toList()..sort();
  }

  @override
  Future<List<RouteOption>> findOptions(TripRequest request) async {
    final rows = await _loadRows();
    return rows
        .where((row) => row['origin'] == request.origin && row['destination'] == request.destination)
        .map(RouteOption.fromJson)
        .toList();
  }
}

final routeRepositoryProvider = Provider<RouteRepository>((ref) => AssetRouteRepository());
