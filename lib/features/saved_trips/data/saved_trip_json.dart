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
  return SavedTrip(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    origin: _requiredString(json, 'origin'),
    destination: _requiredString(json, 'destination'),
    arriveBy: _requiredDate(json, 'arriveBy'),
    optionLabel: _optionalString(json, 'optionLabel'),
    departAt: _optionalDate(json, 'departAt'),
    note: _optionalString(json, 'note'),
    createdAt: _requiredDate(json, 'createdAt'),
  );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Field "$key" wajib berupa teks yang tidak kosong');
  }
  return value;
}

String _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return '';
  if (value is! String) throw FormatException('Field "$key" harus berupa teks');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw FormatException('Field "$key" bukan tanggal yang valid');
  return parsed;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return _requiredDate(json, key);
}
