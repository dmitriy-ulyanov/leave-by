import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/presentation/planner_screen.dart';

import '../helpers/fake_route_repository.dart';
import '../helpers/fake_saved_trip_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('planner: hasil pencarian diumumkan dengan jumlah opsi', (tester) async {
    await pumpApp(
      tester,
      home: const PlannerScreen(),
      extraOverrides: [routeRepositoryProvider.overrideWithValue(FakeRouteRepository())],
    );
    await tester.pumpAndSettle();
    await fillPlannerForm(tester);
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Ditemukan 1 opsi rute'), findsOneWidget);
  });

  testWidgets('planner: saat mencari tampil teks Mencari rute lalu hilang', (tester) async {
    final routes = FakeRouteRepository()..findGate = Completer<void>();
    await pumpApp(
      tester,
      home: const PlannerScreen(),
      extraOverrides: [routeRepositoryProvider.overrideWithValue(routes)],
    );
    await tester.pumpAndSettle();
    await fillPlannerForm(tester);

    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pump();
    expect(find.text('Mencari rute…'), findsOneWidget);

    routes.findGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Mencari rute…'), findsNothing);
    expect(find.text('Taksi online'), findsOneWidget);
  });

  testWidgets('hapus: pesan konfirmasi muncul dan Urungkan mengembalikan perjalanan', (tester) async {
    final repo = FakeSavedTripRepository([sampleTripA, sampleTripB]);
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deleteTrip_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDialogConfirm')));
    await tester.pumpAndSettle();

    expect(find.text('Perjalanan dihapus.'), findsOneWidget);
    expect(find.text('Ke bandara pagi'), findsNothing);

    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();

    expect(find.text('Ke bandara pagi'), findsOneWidget);
    expect(repo.trips.map((t) => t.id), contains('a'));
  });

  testWidgets('simpan: pesan berhasil muncul setelah formulir ditutup', (tester) async {
    final repo = FakeSavedTripRepository();
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addTripButton')));
    await tester.pumpAndSettle();
    await fillTripForm(tester);

    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Perjalanan tersimpan.'), findsOneWidget);
    expect(find.text('Ke bandara'), findsOneWidget);
  });
}
