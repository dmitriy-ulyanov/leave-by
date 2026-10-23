import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leave_by/core/network/api_exception.dart';
import 'package:leave_by/features/saved_trips/data/remote_saved_trip_repository.dart';
import 'package:leave_by/features/saved_trips/domain/saved_trip.dart';

Map<String, dynamic> tripJson(String id, String title) => {
      'id': id,
      'title': title,
      'origin': 'Tebet',
      'destination': 'Bandara Soekarno-Hatta',
      'arriveBy': '2026-10-03T12:00:00.000',
      'optionLabel': 'Taksi online',
      'departAt': '2026-10-03T10:40:00.000',
      'note': '',
      'createdAt': '2026-10-01T00:00:00.000',
    };

RemoteSavedTripRepository repositoryWith(MockClient client, {Duration? timeout}) {
  return RemoteSavedTripRepository(
    client: client,
    baseUrl: 'http://localhost:8000/',
    timeout: timeout ?? const Duration(seconds: 10),
  );
}

final sampleTrip = SavedTrip(
  id: 'a',
  title: 'Ke bandara pagi',
  origin: 'Tebet',
  destination: 'Bandara Soekarno-Hatta',
  arriveBy: DateTime(2026, 10, 3, 12, 0),
  createdAt: DateTime(2026, 10, 1),
  optionLabel: 'Taksi online',
  departAt: DateTime(2026, 10, 3, 10, 40),
);

Matcher apiError({int? statusCode, String? messageContains}) {
  return isA<ApiException>()
      .having((e) => e.statusCode, 'statusCode', statusCode)
      .having((e) => e.message, 'message', messageContains == null ? anything : contains(messageContains));
}

void main() {
  test('API sukses: data diambil dari GET /api/trips', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode([tripJson('a', 'Ke bandara pagi'), tripJson('b', 'Ke stasiun sore')]), 200);
    });

    final trips = await repositoryWith(client).getAll();

    expect(captured.method, 'GET');
    expect(captured.url.toString(), 'http://localhost:8000/api/trips');
    expect(trips.map((t) => t.title), ['Ke bandara pagi', 'Ke stasiun sore']);
  });

  test('data kosong: respons [] menghasilkan daftar kosong', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    expect(await repositoryWith(client).getAll(), isEmpty);
  });

  test('HTTP gagal: status 500 menjadi ApiException dengan kode', () async {
    final client = MockClient((_) async => http.Response('error', 500));
    expect(() => repositoryWith(client).getAll(), throwsA(apiError(statusCode: 500)));
  });

  test('JSON rusak: badan bukan JSON menjadi ApiException', () async {
    final client = MockClient((_) async => http.Response('ini bukan json', 200));
    expect(() => repositoryWith(client).getAll(), throwsA(apiError(messageContains: 'tidak dapat dibaca')));
  });

  test('JSON rusak: badan kosong menjadi ApiException', () async {
    final client = MockClient((_) async => http.Response('', 200));
    expect(() => repositoryWith(client).getAll(), throwsA(apiError(messageContains: 'tidak dapat dibaca')));
  });

  test('JSON rusak: bentuknya bukan daftar', () async {
    final client = MockClient((_) async => http.Response('{"id":"a"}', 200));
    expect(() => repositoryWith(client).getAll(), throwsA(apiError(messageContains: 'tidak dapat dibaca')));
  });

  test('model invalid dari server: elemen tanpa judul menjadi ApiException', () async {
    final broken = tripJson('a', 'x')..remove('title');
    final client = MockClient((_) async => http.Response(jsonEncode([broken]), 200));
    expect(() => repositoryWith(client).getAll(), throwsA(apiError(messageContains: 'tidak dapat dibaca')));
  });

  test('jaringan putus: SocketException menjadi pesan koneksi', () async {
    final client = MockClient((_) async => throw const SocketException('tidak ada jaringan'));
    expect(() => repositoryWith(client).getAll(), throwsA(apiError(messageContains: 'terhubung')));
  });

  test('timeout: server lambat menjadi pesan timeout', () async {
    final client = MockClient((_) => Completer<http.Response>().future);
    final repository = repositoryWith(client, timeout: const Duration(milliseconds: 50));
    await expectLater(repository.getAll(), throwsA(apiError(messageContains: 'tidak merespons')));
  });

  test('save: mengirim PUT dengan badan JSON lengkap', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode(tripJson('a', 'Ke bandara pagi')), 200);
    });

    await repositoryWith(client).save(sampleTrip);

    expect(captured.method, 'PUT');
    expect(captured.url.toString(), 'http://localhost:8000/api/trips/a');
    expect(captured.headers['Content-Type'], contains('application/json'));
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['id'], 'a');
    expect(body['title'], 'Ke bandara pagi');
    expect(body['arriveBy'], '2026-10-03T12:00:00.000');
  });

  test('save: server menolak (422) menjadi ApiException', () async {
    final client = MockClient((_) async => http.Response('{"detail":"x"}', 422));
    expect(() => repositoryWith(client).save(sampleTrip), throwsA(apiError(statusCode: 422)));
  });

  test('delete: mengirim DELETE dan menerima 204', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('', 204);
    });

    await repositoryWith(client).delete('a');

    expect(captured.method, 'DELETE');
    expect(captured.url.toString(), 'http://localhost:8000/api/trips/a');
  });

  test('delete: id yang sudah tidak ada (404) dianggap berhasil', () async {
    final client = MockClient((_) async => http.Response('{"detail":"x"}', 404));
    await repositoryWith(client).delete('zzz');
  });

  test('delete: kesalahan server (500) menjadi ApiException', () async {
    final client = MockClient((_) async => http.Response('', 500));
    expect(() => repositoryWith(client).delete('a'), throwsA(apiError(statusCode: 500)));
  });
}
