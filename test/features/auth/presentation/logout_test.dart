import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/domain/route_option.dart';
import 'package:leave_by/features/planner/domain/trip_request.dart';
import 'package:leave_by/features/planner/presentation/planner_screen.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/pump_auth_app.dart';

class FakeRouteRepository implements RouteRepository {
  @override
  Future<List<String>> loadPlaces() async => const ['Bandara Soekarno-Hatta', 'Tebet'];

  @override
  Future<List<RouteOption>> findOptions(TripRequest request) async => const [];
}

Future<InMemorySessionStore> pumpSignedIn(WidgetTester tester) async {
  final store = InMemorySessionStore(sampleSession);
  await pumpAuthApp(
    tester,
    repository: FakeAuthRepository(),
    store: store,
    child: const PlannerScreen(),
    extraOverrides: [routeRepositoryProvider.overrideWithValue(FakeRouteRepository())],
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('keluar: dialog konfirmasi lalu kembali ke layar masuk', (tester) async {
    final store = await pumpSignedIn(tester);
    expect(find.byKey(const Key('searchButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmDialogConfirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginSubmitButton')), findsOneWidget);
    expect(find.byKey(const Key('searchButton')), findsNothing);
    expect(find.text('Kamu sudah keluar.'), findsOneWidget);
    expect(store.session, isNull);
  });

  testWidgets('keluar dibatalkan: tetap masuk', (tester) async {
    final store = await pumpSignedIn(tester);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmDialogCancel')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('searchButton')), findsOneWidget);
    expect(store.session, isNotNull);
  });
}
