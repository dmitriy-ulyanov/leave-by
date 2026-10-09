import '../domain/departure_advice.dart';

class PlannerData {
  const PlannerData({
    required this.places,
    this.results,
    this.isSubmitting = false,
    this.searchError,
  });

  final List<String> places;
  final List<DepartureAdvice>? results;
  final bool isSubmitting;
  final String? searchError;

  PlannerData copyWith({
    List<DepartureAdvice>? results,
    bool? isSubmitting,
    String? searchError,
    bool clearSearchError = false,
  }) {
    return PlannerData(
      places: places,
      results: results ?? this.results,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      searchError: clearSearchError ? null : (searchError ?? this.searchError),
    );
  }
}
