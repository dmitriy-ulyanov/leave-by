import 'dart:async';

import 'package:leave_by/features/auth/data/auth_repository.dart';
import 'package:leave_by/features/auth/data/session_store.dart';
import 'package:leave_by/features/auth/domain/auth_session.dart';

const sampleSession = AuthSession(
  token: 'token-123',
  userId: 'u1',
  email: 'david@contoh.com',
  name: 'David',
);

class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this.session]);

  AuthSession? session;
  Completer<void>? readGate;
  int clearCalls = 0;

  @override
  Future<AuthSession?> read() async {
    if (readGate != null) await readGate!.future;
    return session;
  }

  @override
  Future<void> write(AuthSession value) async {
    session = value;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    session = null;
  }
}

class FakeAuthRepository implements AuthRepository {
  Object? error;
  Completer<void>? gate;
  AuthSession session = sampleSession;
  int loginCalls = 0;
  int registerCalls = 0;
  String? lastEmail;
  String? lastName;

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    loginCalls++;
    lastEmail = email;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return session;
  }

  @override
  Future<AuthSession> register({required String name, required String email, required String password}) async {
    registerCalls++;
    lastName = name;
    lastEmail = email;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
    return session;
  }
}
