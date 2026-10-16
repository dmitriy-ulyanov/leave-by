import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_trip_providers.dart';
import '../domain/saved_trip.dart';

final savedTripsProvider = AsyncNotifierProvider<SavedTripsNotifier, List<SavedTrip>>(SavedTripsNotifier.new);

class SavedTripsNotifier extends AsyncNotifier<List<SavedTrip>> {
  @override
  Future<List<SavedTrip>> build() => ref.read(savedTripRepositoryProvider).getAll();

  Future<bool> remove(String id) async {
    final repository = ref.read(savedTripRepositoryProvider);
    try {
      await repository.delete(id);
      state = AsyncData(await repository.getAll());
      return true;
    } catch (_) {
      return false;
    }
  }
}
