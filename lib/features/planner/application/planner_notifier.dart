import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../data/route_repository.dart';
import '../domain/departure_calculator.dart';
import '../domain/trip_request.dart';
import 'planner_state.dart';

final departureCalculatorProvider = Provider<DepartureCalculator>((ref) => const DepartureCalculator());

final plannerProvider = AsyncNotifierProvider<PlannerNotifier, PlannerData>(PlannerNotifier.new);

class PlannerNotifier extends AsyncNotifier<PlannerData> {
  @override
  Future<PlannerData> build() async {
    final places = await ref.read(routeRepositoryProvider).loadPlaces();
    return PlannerData(places: places);
  }

  Future<void> search(TripRequest request) async {
    final current = state.value;
    if (current == null || current.isSubmitting) return;
    state = AsyncData(current.copyWith(isSubmitting: true, clearSearchError: true));
    try {
      final options = await ref.read(routeRepositoryProvider).findOptions(request);
      final advice = ref.read(departureCalculatorProvider).calculate(
            request,
            options,
            now: ref.read(clockProvider)(),
          );
      state = AsyncData(current.copyWith(results: advice, isSubmitting: false, clearSearchError: true));
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false, searchError: 'Gagal memuat rute. Silakan coba lagi.'));
    }
  }
}
