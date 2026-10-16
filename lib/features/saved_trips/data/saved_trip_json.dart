import '../domain/saved_trip.dart';

Map<String, dynamic> savedTripToJson(SavedTrip trip) {
  return {
    'id': trip.id,
    'title': trip.title,
    'origin': trip.origin,
    'destination': trip.destination,
    'arriveBy': trip.arriveBy.toIso8601String(),
    'optionLabel': trip.optionLabel,
    'departAt': trip.departAt?.toIso8601String(),
    'note': trip.note,
    'createdAt': trip.createdAt.toIso8601String(),
  };
}

SavedTrip savedTripFromJson(Map<String, dynamic> json) {
  final departAt = json['departAt'] as String?;
  return SavedTrip(
    id: json['id'] as String,
    title: json['title'] as String,
    origin: json['origin'] as String,
    destination: json['destination'] as String,
    arriveBy: DateTime.parse(json['arriveBy'] as String),
    optionLabel: (json['optionLabel'] as String?) ?? '',
    departAt: departAt == null ? null : DateTime.parse(departAt),
    note: (json['note'] as String?) ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
