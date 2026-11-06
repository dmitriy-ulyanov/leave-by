import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/auth/data/auth_json.dart';

Map<String, dynamic> validJson() => {
      'token': 'abc.def.ghi',
      'user': {'id': 'u1', 'email': 'david@contoh.com', 'name': 'David'},
    };

void main() {
  test('model valid: JSON lengkap menjadi AuthSession', () {
    final session = authSessionFromJson(validJson());
    expect(session.token, 'abc.def.ghi');
    expect(session.userId, 'u1');
    expect(session.email, 'david@contoh.com');
    expect(session.name, 'David');
  });

  test('model invalid: token hilang ditolak', () {
    final json = validJson()..remove('token');
    expect(() => authSessionFromJson(json), throwsA(isA<FormatException>()));
  });

  test('model invalid: user bukan objek ditolak', () {
    final json = validJson()..['user'] = 'david';
    expect(() => authSessionFromJson(json), throwsA(isA<FormatException>()));
  });

  test('model invalid: email kosong ditolak', () {
    final json = validJson();
    (json['user'] as Map<String, dynamic>)['email'] = '';
    expect(() => authSessionFromJson(json), throwsA(isA<FormatException>()));
  });

  test('toJson lalu fromJson menghasilkan data yang sama', () {
    final session = authSessionFromJson(validJson());
    final copy = authSessionFromJson(authSessionToJson(session));
    expect(copy.token, session.token);
    expect(copy.userId, session.userId);
    expect(copy.name, session.name);
  });
}
