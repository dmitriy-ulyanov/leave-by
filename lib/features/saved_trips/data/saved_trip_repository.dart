import '../domain/saved_trip.dart';

abstract class SavedTripRepository {
  Future<List<SavedTrip>> getAll();

  Future<void> save(SavedTrip trip);

  Future<void> delete(String id);
}
