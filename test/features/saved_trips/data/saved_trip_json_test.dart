import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/saved_trips/data/saved_trip_json.dart';

Map<String, dynamic> validJson() => {
      'id': 'a',
      'title': 'Ke bandara pagi',
      'origin': 'Tebet',
      'destination': 'Bandara Soekarno-Hatta',
      'arriveBy': '2026-10-03T12:00:00.000',
      'optionLabel': 'Taksi online',
      'departAt': '2026-10-03T10:40:00.000',
      'note': '',
      'createdAt': '2026-10-01T00:00:00.000',
    };

void main() {
  test('model valid: JSON lengkap menjadi SavedTrip', () {
    final trip = savedTripFromJson(validJson());
    expect(trip.id, 'a');
    expect(trip.title, 'Ke bandara pagi');
    expect(trip.arriveBy, DateTime(2026, 10, 3, 12, 0));
    expect(trip.departAt, DateTime(2026, 10, 3, 10, 40));
    expect(trip.optionLabel, 'Taksi online');
  });

  test('model valid: field opsional boleh kosong atau null', () {
    final json = validJson()
      ..['departAt'] = null
      ..remove('optionLabel')
      ..remove('note');
    final trip = savedTripFromJson(json);
    expect(trip.departAt, isNull);
    expect(trip.optionLabel, '');
    expect(trip.note, '');
  });

  test('model invalid: field wajib hilang menimbulkan FormatException', () {
    final json = validJson()..remove('title');
    expect(() => savedTripFromJson(json), throwsA(isA<FormatException>()));
  });

  test('model invalid: judul kosong ditolak', () {
    final json = validJson()..['title'] = '   ';
    expect(() => savedTripFromJson(json), throwsA(isA<FormatException>()));
  });

  test('model invalid: tanggal bukan format ISO ditolak', () {
    final json = validJson()..['arriveBy'] = 'besok pagi';
    expect(() => savedTripFromJson(json), throwsA(isA<FormatException>()));
  });

  test('model invalid: tipe data salah ditolak', () {
    final json = validJson()..['origin'] = 123;
    expect(() => savedTripFromJson(json), throwsA(isA<FormatException>()));
  });

  test('toJson lalu fromJson menghasilkan data yang sama', () {
    final trip = savedTripFromJson(validJson());
    final copy = savedTripFromJson(savedTripToJson(trip));
    expect(copy.id, trip.id);
    expect(copy.arriveBy, trip.arriveBy);
    expect(copy.departAt, trip.departAt);
    expect(copy.createdAt, trip.createdAt);
  });
}
