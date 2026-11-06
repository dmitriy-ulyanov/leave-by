import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leave_by/core/network/api_exception.dart';
import 'package:leave_by/features/auth/data/remote_auth_repository.dart';

String authBody({String name = 'David'}) => jsonEncode({
      'token': 'abc.def.ghi',
      'user': {'id': 'u1', 'email': 'david@contoh.com', 'name': name},
    });

RemoteAuthRepository repositoryWith(MockClient client, {Duration? timeout}) {
  return RemoteAuthRepository(
    client: client,
    baseUrl: 'http://localhost:8765/',
    timeout: timeout ?? const Duration(seconds: 10),
  );
}

Matcher apiError({int? statusCode, String? message, String? messageContains}) {
  return isA<ApiException>()
      .having((e) => e.statusCode, 'statusCode', statusCode)
      .having(
        (e) => e.message,
        'message',
        message != null
            ? equals(message)
            : (messageContains != null ? contains(messageContains) : anything),
      );
}

void main() {
  test('login sukses: mengirim POST dan mengembalikan sesi', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(authBody(), 200);
    });

    final session = await repositoryWith(client).login(email: 'david@contoh.com', password: 'rahasia123');

    expect(captured.method, 'POST');
    expect(captured.url.toString(), 'http://localhost:8765/api/auth/login');
    expect(jsonDecode(captured.body), {'email': 'david@contoh.com', 'password': 'rahasia123'});
    expect(session.token, 'abc.def.ghi');
    expect(session.name, 'David');
  });

  test('register sukses: mengirim nama, email, dan kata sandi', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(authBody(), 201);
    });

    final session = await repositoryWith(client).register(
      name: 'David',
      email: 'david@contoh.com',
      password: 'rahasia123',
    );

    expect(captured.url.toString(), 'http://localhost:8765/api/auth/register');
    expect(jsonDecode(captured.body)['name'], 'David');
    expect(session.userId, 'u1');
  });

  test('nama berhuruf non-ASCII dibaca benar walau tanpa charset', () async {
    final client = MockClient((_) async {
      return http.Response.bytes(utf8.encode(authBody(name: 'Dávid → Ünal')), 200,
          headers: {'content-type': 'application/json'});
    });
    final session = await repositoryWith(client).login(email: 'a@b.co', password: 'x');
    expect(session.name, 'Dávid → Ünal');
  });

  test('401: pesan dari server dipakai', () async {
    final client = MockClient(
      (_) async => http.Response('{"detail":"Email atau kata sandi salah"}', 401),
    );
    await expectLater(
      repositoryWith(client).login(email: 'a@b.co', password: 'salah'),
      throwsA(apiError(statusCode: 401, message: 'Email atau kata sandi salah')),
    );
  });

  test('409: email sudah terdaftar', () async {
    final client = MockClient((_) async => http.Response('{"detail":"Email sudah terdaftar"}', 409));
    await expectLater(
      repositoryWith(client).register(name: 'D', email: 'a@b.co', password: 'rahasia123'),
      throwsA(apiError(statusCode: 409, message: 'Email sudah terdaftar')),
    );
  });

  test('422 tanpa pesan teks: memakai pesan umum berisi kode', () async {
    final client = MockClient((_) async => http.Response('{"detail":[{"msg":"x"}]}', 422));
    await expectLater(
      repositoryWith(client).login(email: 'a@b.co', password: 'x'),
      throwsA(apiError(statusCode: 422, messageContains: '422')),
    );
  });

  test('HTTP gagal: 500 menjadi ApiException dengan kode', () async {
    final client = MockClient((_) async => http.Response('error', 500));
    await expectLater(
      repositoryWith(client).login(email: 'a@b.co', password: 'x'),
      throwsA(apiError(statusCode: 500)),
    );
  });

  test('JSON rusak: badan bukan JSON', () async {
    final client = MockClient((_) async => http.Response('bukan json', 200));
    await expectLater(
      repositoryWith(client).login(email: 'a@b.co', password: 'x'),
      throwsA(apiError(messageContains: 'tidak dapat dibaca')),
    );
  });

  test('model invalid dari server: token hilang', () async {
    final client = MockClient((_) async => http.Response('{"user":{"id":"u1","email":"a@b.co","name":"D"}}', 200));
    await expectLater(
      repositoryWith(client).login(email: 'a@b.co', password: 'x'),
      throwsA(apiError(messageContains: 'tidak dapat dibaca')),
    );
  });

  test('jaringan putus menjadi pesan koneksi', () async {
    final client = MockClient((_) async => throw const SocketException('tidak ada jaringan'));
    await expectLater(
      repositoryWith(client).login(email: 'a@b.co', password: 'x'),
      throwsA(apiError(messageContains: 'terhubung')),
    );
  });

  test('timeout menjadi pesan timeout', () async {
    final client = MockClient((_) => Completer<http.Response>().future);
    final repository = repositoryWith(client, timeout: const Duration(milliseconds: 50));
    await expectLater(
      repository.login(email: 'a@b.co', password: 'x'),
      throwsA(apiError(messageContains: 'tidak merespons')),
    );
  });
}
