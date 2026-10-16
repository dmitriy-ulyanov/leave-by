import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/shared/widgets/empty_view.dart';
import 'package:leave_by/shared/widgets/error_view.dart';

import '../../../helpers/fake_saved_trip_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('initial loading: spinner tampil lalu daftar muncul', (tester) async {
    final repo = FakeSavedTripRepository([sampleTripA])..getAllGate = Completer<void>();
    await pumpApp(tester, repository: repo);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.getAllGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara pagi'), findsOneWidget);
  });

  testWidgets('data berhasil dimuat: semua perjalanan tampil', (tester) async {
    await pumpApp(tester, repository: FakeSavedTripRepository([sampleTripA, sampleTripB]));
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara pagi'), findsOneWidget);
    expect(find.text('Ke stasiun sore'), findsOneWidget);
  });

  testWidgets('empty state: belum ada perjalanan tersimpan', (tester) async {
    await pumpApp(tester, repository: FakeSavedTripRepository());
    await tester.pumpAndSettle();
    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('error state: tombol Coba Lagi memuat ulang', (tester) async {
    final repo = FakeSavedTripRepository([sampleTripA])..getAllError = Exception('gagal');
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    repo.getAllError = null;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.text('Ke bandara pagi'), findsOneWidget);
  });

  testWidgets('hapus: dialog konfirmasi lalu perjalanan terhapus', (tester) async {
    final repo = FakeSavedTripRepository([sampleTripA, sampleTripB]);
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deleteTrip_a')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus perjalanan?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDialogConfirm')));
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara pagi'), findsNothing);
    expect(find.text('Ke stasiun sore'), findsOneWidget);
    expect(repo.deleteCalls, 1);
  });

  testWidgets('hapus: batal menyimpan perjalanan tetap ada', (tester) async {
    final repo = FakeSavedTripRepository([sampleTripA]);
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deleteTrip_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDialogCancel')));
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara pagi'), findsOneWidget);
    expect(repo.deleteCalls, 0);
  });
}
