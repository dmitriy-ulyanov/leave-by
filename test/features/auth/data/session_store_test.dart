import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/auth/data/session_store.dart';
import 'package:leave_by/features/auth/domain/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

const session = AuthSession(token: 'abc.def.ghi', userId: 'u1', email: 'david@contoh.com', name: 'David');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tanpa sesi tersimpan menghasilkan null', () async {
    expect(await SharedPrefsSessionStore().read(), isNull);
  });

  test('sesi yang ditulis bisa dibaca kembali setelah dibuka ulang', () async {
    await SharedPrefsSessionStore().write(session);
    final stored = (await SharedPreferences.getInstance()).getString(SharedPrefsSessionStore.storageKey);
    expect(stored, isNotNull);
    SharedPreferences.setMockInitialValues({SharedPrefsSessionStore.storageKey: stored!});

    final restored = await SharedPrefsSessionStore().read();
    expect(restored?.token, 'abc.def.ghi');
    expect(restored?.name, 'David');
  });

  test('clear menghapus sesi', () async {
    final store = SharedPrefsSessionStore();
    await store.write(session);
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('data sesi rusak menimbulkan FormatException', () async {
    SharedPreferences.setMockInitialValues({SharedPrefsSessionStore.storageKey: jsonEncode({'token': 'x'})});
    expect(() => SharedPrefsSessionStore().read(), throwsA(isA<FormatException>()));
  });
}
