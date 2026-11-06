import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/presentation/planner_screen.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_route_repository.dart';
import '../helpers/fake_saved_trip_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/pump_auth_app.dart';

String describe(WidgetTester tester, Finder finder) {
  final data = tester.getSemantics(finder).getSemanticsData();
  return '${data.label} ${data.tooltip}';
}

Future<void> openPlannerWithResults(WidgetTester tester, {Size? size, double textScale = 1.0}) async {
  await pumpApp(
    tester,
    size: size ?? const Size(800, 1600),
    textScale: textScale,
    home: const PlannerScreen(),
    extraOverrides: [routeRepositoryProvider.overrideWithValue(FakeRouteRepository())],
  );
  await tester.pumpAndSettle();
  await fillPlannerForm(tester);
  await tester.tap(find.byKey(const Key('searchButton')));
  await tester.pumpAndSettle();
}

void main() {
  group('label dan target sentuh', () {
    testWidgets('tombol ikon pada daftar punya label yang membedakan tiap perjalanan', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, repository: FakeSavedTripRepository([sampleTripA, sampleTripB]));
      await tester.pumpAndSettle();

      expect(describe(tester, find.byKey(const Key('deleteTrip_a'))), contains('Hapus Ke bandara pagi'));
      expect(describe(tester, find.byKey(const Key('deleteTrip_b'))), contains('Hapus Ke stasiun sore'));
      expect(describe(tester, find.byKey(const Key('editTrip_a'))), contains('Ubah Ke bandara pagi'));
      handle.dispose();
    });

    testWidgets('layar masuk memenuhi pedoman target sentuh dan label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAuthApp(tester, repository: FakeAuthRepository(), store: InMemorySessionStore());
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('layar daftar memenuhi pedoman target sentuh dan label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpAuthApp(tester, repository: FakeAuthRepository(), store: InMemorySessionStore());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('goToRegisterButton')));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('planner dengan hasil memenuhi pedoman target sentuh dan label', (tester) async {
      final handle = tester.ensureSemantics();
      await openPlannerWithResults(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('daftar perjalanan tersimpan memenuhi pedoman target sentuh dan label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, repository: FakeSavedTripRepository([sampleTripA, sampleTripB]));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('kartu rute dibaca sebagai satu kesatuan', (tester) async {
      final handle = tester.ensureSemantics();
      await openPlannerWithResults(tester);

      final text = describe(tester, find.text('Taksi online'));
      expect(text, contains('Taksi online'));
      expect(text, contains('Berangkat paling lambat 10:40'));
      expect(text, contains('250.000'));
      handle.dispose();
    });
  });

  group('teks besar (2x) tidak menyebabkan overflow', () {
    const narrow = Size(400, 900);

    testWidgets('planner dengan hasil', (tester) async {
      await openPlannerWithResults(tester, size: narrow, textScale: 2.0);
      expect(find.text('Taksi online'), findsOneWidget);
    });

    testWidgets('daftar perjalanan tersimpan', (tester) async {
      await pumpApp(
        tester,
        size: narrow,
        textScale: 2.0,
        repository: FakeSavedTripRepository([sampleTripA, sampleTripB]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ke bandara pagi'), findsOneWidget);
    });

    testWidgets('layar masuk dan daftar', (tester) async {
      await pumpAuthApp(
        tester,
        repository: FakeAuthRepository(),
        store: InMemorySessionStore(),
        size: narrow,
        textScale: 2.0,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('goToRegisterButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('registerSubmitButton')), findsOneWidget);
    });

    testWidgets('formulir perjalanan', (tester) async {
      await pumpApp(tester, size: narrow, textScale: 2.0, repository: FakeSavedTripRepository());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addTripButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tripSubmitButton')));
      await tester.pumpAndSettle();
      expect(find.text('Judul wajib diisi'), findsOneWidget);
    });
  });
}
