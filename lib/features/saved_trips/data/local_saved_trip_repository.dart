import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/saved_trip.dart';
import 'saved_trip_json.dart';
import 'saved_trip_repository.dart';

class LocalSavedTripRepository implements SavedTripRepository {
  LocalSavedTripRepository({Future<SharedPreferences> Function()? prefsLoader})
      : _prefsLoader = prefsLoader ?? SharedPreferences.getInstance;

  static const String storageKey = 'saved_trips';

  final Future<SharedPreferences> Function() _prefsLoader;

  @override
  Future<List<SavedTrip>> getAll() async {
    final prefs = await _prefsLoader();
    return _decode(prefs.getString(storageKey));
  }

  @override
  Future<void> save(SavedTrip trip) async {
    final prefs = await _prefsLoader();
    final trips = _decode(prefs.getString(storageKey));
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
    } else {
      trips.insert(0, trip);
    }
    await _write(prefs, trips);
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await _prefsLoader();
    final trips = _decode(prefs.getString(storageKey))..removeWhere((t) => t.id == id);
    await _write(prefs, trips);
  }

  List<SavedTrip> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return <SavedTrip>[];
    final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return rows.map(savedTripFromJson).toList();
  }

  Future<void> _write(SharedPreferences prefs, List<SavedTrip> trips) async {
    final raw = jsonEncode(trips.map(savedTripToJson).toList());
    final written = await prefs.setString(storageKey, raw);
    if (!written) throw StateError('Penyimpanan lokal gagal menulis data');
  }
}
