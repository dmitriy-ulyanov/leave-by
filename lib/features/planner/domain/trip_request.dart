class TripRequest {
  const TripRequest({required this.origin, required this.destination, required this.arriveBy});

  final String origin;
  final String destination;
  final DateTime arriveBy;
}
