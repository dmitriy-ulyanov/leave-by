import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/auth/application/auth_notifier.dart';
import 'package:leave_by/features/auth/data/auth_providers.dart';
import 'package:leave_by/features/auth/data/session_store.dart';
import 'package:leave_by/features/auth/domain/auth_session.dart';

import '../../../helpers/fake_auth_repository.dart';

class ThrowingSessionStore implements SessionStore {
  int clearCalls = 0;

  @override
  Future<AuthSession?> read() async => throw const FormatException('rusak');

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}

ProviderContainer makeContainer(SessionStore store) {
  final container = ProviderContainer(overrides: [sessionStoreProvider.overrideWithValue(store)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('memuat sesi yang tersimpan saat aplikasi dibuka', () async {
    final container = makeContainer(InMemorySessionStore(sampleSession));
    final session = await container.read(authProvider.future);
    expect(session?.userId, 'u1');
  });

  test('tanpa sesi tersimpan: belum masuk', () async {
    final container = makeContainer(InMemorySessionStore());
    expect(await container.read(authProvider.future), isNull);
  });

  test('sesi tersimpan rusak dianggap belum masuk dan dibersihkan', () async {
    final store = ThrowingSessionStore();
    final container = makeContainer(store);
    expect(await container.read(authProvider.future), isNull);
    expect(store.clearCalls, 1);
  });

  test('signIn menyimpan sesi dan mengubah state', () async {
    final store = InMemorySessionStore();
    final container = makeContainer(store);
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).signIn(sampleSession);

    expect(container.read(authProvider).value?.token, 'token-123');
    expect(store.session?.token, 'token-123');
  });

  test('signOut menghapus sesi dan mengubah state', () async {
    final store = InMemorySessionStore(sampleSession);
    final container = makeContainer(store);
    await container.read(authProvider.future);

    await container.read(authProvider.notifier).signOut();

    expect(container.read(authProvider).value, isNull);
    expect(store.session, isNull);
  });
}
