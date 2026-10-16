import 'dart:async';

import 'package:leave_by/features/saved_trips/data/saved_trip_repository.dart';
import 'package:leave_by/features/saved_trips/domain/saved_trip.dart';

final sampleTripA = SavedTrip(
  id: 'a',
  title: 'Ke bandara pagi',
  origin: 'Tebet',
  destination: 'Bandara Soekarno-Hatta',
  arriveBy: DateTime(2026, 10, 3, 12, 0),
  createdAt: DateTime(2026, 10, 1),
  optionLabel: 'Taksi online',
  departAt: DateTime(2026, 10, 3, 10, 40),
);

final sampleTripB = SavedTrip(
  id: 'b',
  title: 'Ke stasiun sore',
  origin: 'Depok',
  destination: 'Stasiun Gambir',
  arriveBy: DateTime(2026, 10, 3, 17, 30),
  createdAt: DateTime(2026, 10, 2),
);

class FakeSavedTripRepository implements SavedTripRepository {
  FakeSavedTripRepository([List<SavedTrip> initial = const []]) : trips = List.of(initial);

  List<SavedTrip> trips;
  Object? getAllError;
  Object? saveError;
  Completer<void>? getAllGate;
  Completer<void>? saveGate;
  int saveCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<SavedTrip>> getAll() async {
    if (getAllGate != null) await getAllGate!.future;
    if (getAllError != null) throw getAllError!;
    return List.of(trips);
  }

  @override
  Future<void> save(SavedTrip trip) async {
    saveCalls++;
    if (saveGate != null) await saveGate!.future;
    if (saveError != null) throw saveError!;
    final index = trips.indexWhere((t) => t.id == trip.id);
    if (index >= 0) {
      trips[index] = trip;
    } else {
      trips.insert(0, trip);
    }
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    trips.removeWhere((t) => t.id == id);
  }
}
