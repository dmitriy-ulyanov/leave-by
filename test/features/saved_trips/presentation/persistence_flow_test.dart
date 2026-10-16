import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/domain/route_option.dart';
import 'package:leave_by/features/planner/domain/transport_mode.dart';
import 'package:leave_by/features/planner/domain/trip_request.dart';
import 'package:leave_by/features/planner/presentation/planner_screen.dart';
import 'package:leave_by/features/saved_trips/data/local_saved_trip_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_saved_trip_repository.dart';
import '../../../helpers/pump_app.dart';

const taxi = RouteOption(
  id: 'taxi',
  mode: TransportMode.taksiOnline,
  label: 'Taksi online',
  travelMinutes: 60,
  transitCount: 0,
  costRupiah: 250000,
);

class FakeRouteRepository implements RouteRepository {
  @override
  Future<List<String>> loadPlaces() async => const ['Bandara Soekarno-Hatta', 'Tebet'];

  @override
  Future<List<RouteOption>> findOptions(TripRequest request) async => const [taxi];
}

void main() {
  testWidgets('CRUD lewat UI dengan penyimpanan lokal: data tetap ada setelah dibuka ulang', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada perjalanan tersimpan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addTripButton')));
    await tester.pumpAndSettle();
    await fillTripForm(tester);
    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara'), findsOneWidget);

    final stored = (await SharedPreferences.getInstance()).getString(LocalSavedTripRepository.storageKey);
    expect(stored, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    SharedPreferences.setMockInitialValues({LocalSavedTripRepository.storageKey: stored!});

    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.text('Ke bandara'), findsOneWidget);
  });

  testWidgets('simpan dari hasil planner lalu lihat di daftar tersimpan', (tester) async {
    final saved = FakeSavedTripRepository();
    await pumpApp(
      tester,
      repository: saved,
      home: const PlannerScreen(),
      extraOverrides: [routeRepositoryProvider.overrideWithValue(FakeRouteRepository())],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('originField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tebet').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('destinationField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bandara Soekarno-Hatta').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('arriveByField')), '12:00');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveTrip_taxi')));
    await tester.pumpAndSettle();
    final titleField = tester.widget<TextFormField>(find.byKey(const Key('tripTitleField')));
    expect(titleField.controller!.text, 'Tebet → Bandara Soekarno-Hatta');

    await tester.tap(find.byKey(const Key('tripSubmitButton')));
    await tester.pumpAndSettle();
    expect(saved.trips.single.optionLabel, 'Taksi online');

    await tester.tap(find.byKey(const Key('openSavedButton')));
    await tester.pumpAndSettle();
    expect(find.text('Tebet → Bandara Soekarno-Hatta'), findsOneWidget);
  });
}
