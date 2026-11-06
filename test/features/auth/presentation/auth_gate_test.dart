import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_auth_app.dart';

void main() {
  testWidgets('initial loading: spinner tampil saat sesi dibaca', (tester) async {
    final store = InMemorySessionStore(sampleSession)..readGate = Completer<void>();
    await pumpAuthApp(tester, repository: FakeAuthRepository(), store: store);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(homeMarker), findsNothing);

    store.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text(homeMarker), findsOneWidget);
  });

  testWidgets('tanpa sesi: layar masuk tampil', (tester) async {
    await pumpAuthApp(tester, repository: FakeAuthRepository(), store: InMemorySessionStore());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
    expect(find.text(homeMarker), findsNothing);
  });

  testWidgets('dengan sesi tersimpan: langsung masuk ke beranda', (tester) async {
    await pumpAuthApp(tester, repository: FakeAuthRepository(), store: InMemorySessionStore(sampleSession));
    await tester.pumpAndSettle();
    expect(find.text(homeMarker), findsOneWidget);
    expect(find.byKey(const Key('loginSubmitButton')), findsNothing);
  });
}
