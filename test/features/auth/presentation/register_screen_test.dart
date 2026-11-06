import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/core/network/api_exception.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_auth_app.dart';

Future<void> openRegister(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('goToRegisterButton')));
  await tester.pumpAndSettle();
}

Future<void> fillRegister(
  WidgetTester tester, {
  String name = 'David',
  String email = 'david@contoh.com',
  String password = 'rahasia123',
  String confirm = 'rahasia123',
}) async {
  await tester.enterText(find.byKey(const Key('registerNameField')), name);
  await tester.enterText(find.byKey(const Key('registerEmailField')), email);
  await tester.enterText(find.byKey(const Key('registerPasswordField')), password);
  await tester.enterText(find.byKey(const Key('registerConfirmField')), confirm);
}

void main() {
  testWidgets('validasi: form kosong menampilkan semua pesan', (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();
    await openRegister(tester);

    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await tester.pump();
    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi wajib diisi'), findsOneWidget);
    expect(repo.registerCalls, 0);
  });

  testWidgets('validasi: kata sandi pendek dan konfirmasi berbeda ditolak', (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();
    await openRegister(tester);

    await fillRegister(tester, password: 'pendek', confirm: 'beda');
    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await tester.pump();
    expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);
    expect(find.text('Kata sandi tidak sama'), findsOneWidget);
    expect(repo.registerCalls, 0);
  });

  testWidgets('sukses: akun dibuat, sesi tersimpan, dan beranda tampil', (tester) async {
    final repo = FakeAuthRepository();
    final store = InMemorySessionStore();
    await pumpAuthApp(tester, repository: repo, store: store);
    await tester.pumpAndSettle();
    await openRegister(tester);

    await fillRegister(tester, name: '  David  ');
    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await tester.pumpAndSettle();

    expect(repo.registerCalls, 1);
    expect(repo.lastName, 'David');
    expect(store.session?.token, 'token-123');
    expect(find.text(homeMarker), findsOneWidget);
    expect(find.byKey(const Key('registerSubmitButton')), findsNothing);
  });

  testWidgets('error: email sudah terdaftar menampilkan pesan dan tetap di layar daftar', (tester) async {
    final repo = FakeAuthRepository()..error = const ApiException('Email sudah terdaftar', statusCode: 409);
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();
    await openRegister(tester);
    await fillRegister(tester);

    await tester.tap(find.byKey(const Key('registerSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Email sudah terdaftar'), findsOneWidget);
    expect(find.byKey(const Key('registerSubmitButton')), findsOneWidget);
    expect(find.text(homeMarker), findsNothing);
  });

  testWidgets('pesan error layar masuk tidak terbawa ke layar daftar', (tester) async {
    final repo = FakeAuthRepository()..error = const ApiException('Email atau kata sandi salah', statusCode: 401);
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('loginEmailField')), 'david@contoh.com');
    await tester.enterText(find.byKey(const Key('loginPasswordField')), 'rahasia123');
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('authErrorText')), findsOneWidget);

    await openRegister(tester);
    expect(find.byKey(const Key('authErrorText')), findsNothing);
  });
}
