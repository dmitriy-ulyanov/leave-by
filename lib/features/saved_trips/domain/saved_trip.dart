class SavedTrip {
  const SavedTrip({
    required this.id,
    required this.title,
    required this.origin,
    required this.destination,
    required this.arriveBy,
    required this.createdAt,
    this.optionLabel = '',
    this.departAt,
    this.note = '',
  });

  final String id;
  final String title;
  final String origin;
  final String destination;
  final DateTime arriveBy;
  final String optionLabel;
  final DateTime? departAt;
  final String note;
  final DateTime createdAt;
}
