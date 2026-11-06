import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/core/network/api_exception.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_auth_app.dart';

Future<void> fillLogin(WidgetTester tester, {String email = 'david@contoh.com', String password = 'rahasia123'}) async {
  await tester.enterText(find.byKey(const Key('loginEmailField')), email);
  await tester.enterText(find.byKey(const Key('loginPasswordField')), password);
}

void main() {
  testWidgets('validasi: form kosong menampilkan pesan dan tidak memanggil server', (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('validasi: format email salah ditolak', (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();

    await fillLogin(tester, email: 'bukan-email');
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });

  testWidgets('loading submit: tombol nonaktif dan tidak bisa double tap', (tester) async {
    final repo = FakeAuthRepository()..gate = Completer<void>();
    final store = InMemorySessionStore();
    await pumpAuthApp(tester, repository: repo, store: store);
    await tester.pumpAndSettle();
    await fillLogin(tester);

    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('loginSubmitButton'))).onPressed, isNull);

    await tester.tap(find.byKey(const Key('loginSubmitButton')), warnIfMissed: false);
    await tester.pump();

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.loginCalls, 1);
    expect(find.text(homeMarker), findsOneWidget);
  });

  testWidgets('sukses: sesi disimpan dan beranda tampil', (tester) async {
    final repo = FakeAuthRepository();
    final store = InMemorySessionStore();
    await pumpAuthApp(tester, repository: repo, store: store);
    await tester.pumpAndSettle();

    await fillLogin(tester, email: '  david@contoh.com  ');
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text(homeMarker), findsOneWidget);
    expect(store.session?.token, 'token-123');
    expect(repo.lastEmail, 'david@contoh.com');
  });

  testWidgets('error: kredensial salah menampilkan pesan dan form tetap bisa dipakai', (tester) async {
    final repo = FakeAuthRepository()..error = const ApiException('Email atau kata sandi salah', statusCode: 401);
    final store = InMemorySessionStore();
    await pumpAuthApp(tester, repository: repo, store: store);
    await tester.pumpAndSettle();
    await fillLogin(tester);

    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi salah'), findsOneWidget);
    expect(find.text(homeMarker), findsNothing);
    expect(store.session, isNull);
    expect(tester.widget<FilledButton>(find.byKey(const Key('loginSubmitButton'))).onPressed, isNotNull);

    repo.error = null;
    await tester.tap(find.byKey(const Key('loginSubmitButton')));
    await tester.pumpAndSettle();
    expect(find.text(homeMarker), findsOneWidget);
  });

  testWidgets('kata sandi bisa ditampilkan dan disembunyikan', (tester) async {
    await pumpAuthApp(tester, repository: FakeAuthRepository(), store: InMemorySessionStore());
    await tester.pumpAndSettle();

    EditableText field() => tester.widget<EditableText>(
          find.descendant(
            of: find.byKey(const Key('loginPasswordField')),
            matching: find.byType(EditableText),
          ),
        );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('togglePasswordButton')));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });
}
