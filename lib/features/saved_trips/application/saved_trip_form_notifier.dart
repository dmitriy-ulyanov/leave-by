import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/saved_trip_providers.dart';
import '../domain/saved_trip.dart';
import 'saved_trips_notifier.dart';

class SavedTripFormState {
  const SavedTripFormState({this.isSubmitting = false, this.errorMessage});

  final bool isSubmitting;
  final String? errorMessage;
}

final savedTripFormProvider =
    NotifierProvider<SavedTripFormNotifier, SavedTripFormState>(SavedTripFormNotifier.new);

class SavedTripFormNotifier extends Notifier<SavedTripFormState> {
  @override
  SavedTripFormState build() => const SavedTripFormState();

  Future<bool> submit(SavedTrip trip) async {
    if (state.isSubmitting) return false;
    state = const SavedTripFormState(isSubmitting: true);
    try {
      await ref.read(savedTripRepositoryProvider).save(trip);
      ref.invalidate(savedTripsProvider);
      state = const SavedTripFormState();
      return true;
    } catch (error) {
      final message = error is ApiException ? error.message : 'Gagal menyimpan perjalanan. Coba lagi.';
      state = SavedTripFormState(errorMessage: message);
      return false;
    }
  }
}
