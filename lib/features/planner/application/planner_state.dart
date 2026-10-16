import '../domain/departure_advice.dart';
import '../domain/trip_request.dart';

class PlannerData {
  const PlannerData({
    required this.places,
    this.results,
    this.request,
    this.isSubmitting = false,
    this.searchError,
  });

  final List<String> places;
  final List<DepartureAdvice>? results;
  final TripRequest? request;
  final bool isSubmitting;
  final String? searchError;

  PlannerData copyWith({
    List<DepartureAdvice>? results,
    TripRequest? request,
    bool? isSubmitting,
    String? searchError,
    bool clearSearchError = false,
  }) {
    return PlannerData(
      places: places,
      results: results ?? this.results,
      request: request ?? this.request,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
    );
  }
}
