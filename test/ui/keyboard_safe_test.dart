import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_saved_trip_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/pump_auth_app.dart';

const double screenHeight = 640;
const double keyboardHeight = 320;

Future<void> showKeyboardFor(WidgetTester tester, Finder field) async {
  await tester.tap(field);
  await tester.pump();
  tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpAndSettle();
}

void expectAboveKeyboard(WidgetTester tester, Finder field) {
  final rect = tester.getRect(field);
  expect(rect.bottom, lessThanOrEqualTo(screenHeight - keyboardHeight));
  expect(rect.top, greaterThanOrEqualTo(0));
}

void main() {
  testWidgets('daftar: kolom terakhir tetap terlihat di atas keyboard', (tester) async {
    await pumpAuthApp(
      tester,
      repository: FakeAuthRepository(),
      store: InMemorySessionStore(),
      size: const Size(400, screenHeight),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goToRegisterButton')));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('registerConfirmField'));
    await showKeyboardFor(tester, field);
    expectAboveKeyboard(tester, field);
  });

  testWidgets('form perjalanan: kolom catatan tetap terlihat di atas keyboard', (tester) async {
    await pumpApp(tester, size: const Size(400, screenHeight), repository: FakeSavedTripRepository());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addTripButton')));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('tripNoteField'));
    await showKeyboardFor(tester, field);
    expectAboveKeyboard(tester, field);
  });

  testWidgets('semua formulir berada di dalam area yang bisa digulir', (tester) async {
    await pumpAuthApp(tester, repository: FakeAuthRepository(), store: InMemorySessionStore());
    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: find.byKey(const Key('loginEmailField')), matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('goToRegisterButton')));
    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: find.byKey(const Key('registerNameField')), matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
  });

  testWidgets('tombol Selesai pada kolom terakhir mengirim formulir masuk', (tester) async {
    final repo = FakeAuthRepository();
    await pumpAuthApp(tester, repository: repo, store: InMemorySessionStore());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('loginEmailField')), 'david@contoh.com');
    await tester.enterText(find.byKey(const Key('loginPasswordField')), 'rahasia123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(repo.loginCalls, 1);
    expect(find.text(homeMarker), findsOneWidget);
  });
}
