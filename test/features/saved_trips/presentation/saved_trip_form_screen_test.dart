import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/saved_trips/presentation/saved_trip_form_screen.dart';

import '../../../helpers/fake_saved_trip_repository.dart';
import '../../../helpers/pump_app.dart';

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('addTripButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validasi: form kosong menampilkan pesan dan tidak menyimpan', (tester) async {
    final repo = FakeSavedTripRepository();
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await openForm(tester);

    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pump();
    expect(find.text('Judul wajib diisi'), findsOneWidget);
    expect(find.text('Asal wajib diisi'), findsOneWidget);
    expect(find.text('Tujuan wajib diisi'), findsOneWidget);
    expect(find.text('Jam tiba wajib diisi'), findsOneWidget);
    expect(repo.saveCalls, 0);
  });

  testWidgets('validasi: asal dan tujuan tidak boleh sama', (tester) async {
    final repo = FakeSavedTripRepository();
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await openForm(tester);

    await fillTripForm(tester, destination: 'tebet');
    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pump();
    expect(find.text('Tujuan harus berbeda dari asal'), findsOneWidget);
    expect(repo.saveCalls, 0);
  });

  testWidgets('validasi: format jam dan panjang catatan', (tester) async {
    final repo = FakeSavedTripRepository();
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await openForm(tester);

    await fillTripForm(tester, time: '25:99', note: 'x' * 201);
    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pump();
    expect(find.text('Format jam harus HH:mm'), findsOneWidget);
    expect(find.text('Catatan maksimal 200 karakter'), findsOneWidget);
    expect(repo.saveCalls, 0);
  });

  testWidgets('loading submit: tombol nonaktif dan tidak bisa double tap', (tester) async {
    final repo = FakeSavedTripRepository()..saveGate = Completer<void>();
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await openForm(tester);
    await fillTripForm(tester);

    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('tripSubmitButton'))).onPressed, isNull);

    await tester.tap(find.byKey(const Key('tripSubmitButton')), warnIfMissed: false);
    await tester.pump();

    repo.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.saveCalls, 1);
    expect(find.byType(SavedTripFormScreen), findsNothing);
  });

  testWidgets('create: perjalanan baru muncul di daftar', (tester) async {
    final repo = FakeSavedTripRepository();
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await openForm(tester);
    await fillTripForm(tester, note: 'dekat gerbang 3');

    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedTripFormScreen), findsNothing);
    expect(find.text('Ke bandara'), findsOneWidget);
    expect(repo.trips.length, 1);
    expect(repo.trips.single.note, 'dekat gerbang 3');
  });

  testWidgets('update: form terisi data lama dan perubahan tersimpan', (tester) async {
    final repo = FakeSavedTripRepository([sampleTripA]);
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editTrip_a')));
    await tester.pumpAndSettle();
    final titleField = tester.widget<TextFormField>(find.byKey(const Key('tripTitleField')));
    expect(titleField.controller!.text, 'Ke bandara pagi');

    await tester.enterText(find.byKey(const Key('tripTitleField')), 'Ke bandara siang');
    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara siang'), findsOneWidget);
    expect(repo.trips.length, 1);
    expect(repo.trips.single.id, 'a');
    expect(repo.trips.single.optionLabel, 'Taksi online');
  });

  testWidgets('error submit: pesan muncul dan form tetap terbuka', (tester) async {
    final repo = FakeSavedTripRepository()..saveError = Exception('gagal');
    await pumpApp(tester, repository: repo);
    await tester.pumpAndSettle();
    await openForm(tester);
    await fillTripForm(tester);

    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pumpAndSettle();
    expect(find.text('Gagal menyimpan perjalanan. Coba lagi.'), findsOneWidget);
    expect(find.byType(SavedTripFormScreen), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('tripSubmitButton'))).onPressed, isNotNull);
    expect(repo.saveCalls, 1);
  });
}
