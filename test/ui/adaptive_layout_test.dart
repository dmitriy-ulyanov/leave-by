import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/presentation/planner_screen.dart';
import 'package:leave_by/features/saved_trips/presentation/widgets/saved_trip_tile.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/fake_route_repository.dart';
import '../helpers/fake_saved_trip_repository.dart';
import '../helpers/pump_app.dart';
import '../helpers/pump_auth_app.dart';

Future<void> searchOnPlanner(WidgetTester tester, Size size) async {
  await pumpApp(
    tester,
    size: size,
    home: const PlannerScreen(),
    extraOverrides: [routeRepositoryProvider.overrideWithValue(FakeRouteRepository())],
  );
  await tester.pumpAndSettle();
  await fillPlannerForm(tester);
  await tester.tap(find.byKey(const Key('searchButton')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('layar kecil: hasil berada di bawah formulir', (tester) async {
    await searchOnPlanner(tester, const Size(400, 1200));

    final buttonBottom = tester.getBottomLeft(find.byKey(const Key('searchButton'))).dy;
    final cardTop = tester.getTopLeft(find.text('Taksi online')).dy;
    expect(cardTop, greaterThan(buttonBottom));
  });

  testWidgets('layar besar: hasil berada di samping formulir', (tester) async {
    await searchOnPlanner(tester, const Size(1400, 900));

    final formRight = tester.getTopRight(find.byKey(const Key('searchButton'))).dx;
    final cardLeft = tester.getTopLeft(find.text('Taksi online')).dx;
    expect(cardLeft, greaterThan(formRight));
  });

  testWidgets('layar besar: daftar perjalanan tersimpan dibatasi lebarnya dan di tengah', (tester) async {
    await pumpApp(
      tester,
      size: const Size(1400, 900),
      repository: FakeSavedTripRepository([sampleTripA, sampleTripB]),
    );
    await tester.pumpAndSettle();

    final tile = find.byType(SavedTripTile).first;
    expect(tester.getSize(tile).width, lessThanOrEqualTo(720));
    expect(tester.getCenter(tile).dx, closeTo(700, 1));
  });

  testWidgets('layar besar: formulir perjalanan tidak melebar penuh', (tester) async {
    await pumpApp(tester, size: const Size(1400, 900), repository: FakeSavedTripRepository());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addTripButton')));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const Key('tripTitleField'))).width, lessThanOrEqualTo(560));
  });

  testWidgets('layar besar: formulir masuk tidak melebar penuh', (tester) async {
    await pumpAuthApp(
      tester,
      repository: FakeAuthRepository(),
      store: InMemorySessionStore(),
      size: const Size(1400, 900),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const Key('loginEmailField'))).width, lessThanOrEqualTo(420));
  });
}
