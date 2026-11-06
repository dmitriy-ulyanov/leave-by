import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_providers.dart';
import '../domain/auth_session.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final store = ref.read(sessionStoreProvider);
    try {
      return await store.read();
    } catch (_) {
      try {
        await store.clear();
      } catch (_) {}
      return null;
    }
  }

  Future<void> signIn(AuthSession session) async {
    await ref.read(sessionStoreProvider).write(session);
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    state = const AsyncData(null);
    try {
      await ref.read(sessionStoreProvider).clear();
    } catch (_) {}
  }
}
