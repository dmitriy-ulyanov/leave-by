import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/core/providers/clock_provider.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/domain/route_option.dart';
import 'package:leave_by/features/planner/domain/transport_mode.dart';
import 'package:leave_by/features/planner/domain/trip_request.dart';
import 'package:leave_by/features/planner/presentation/planner_screen.dart';
import 'package:leave_by/shared/widgets/empty_view.dart';
import 'package:leave_by/shared/widgets/error_view.dart';

const taxi = RouteOption(
  id: 'taxi',
  mode: TransportMode.taksiOnline,
  label: 'Taksi online',
  travelMinutes: 60,
  transitCount: 0,
  costRupiah: 250000,
);

class FakeRouteRepository implements RouteRepository {
  FakeRouteRepository({this.options = const [taxi]});

  List<RouteOption> options;
  Object? placesError;
  Completer<void>? placesGate;
  Completer<void>? findGate;
  int findCalls = 0;

  @override
  Future<List<String>> loadPlaces() async {
    if (placesGate != null) await placesGate!.future;
    if (placesError != null) throw placesError!;
    return const ['Bandara Soekarno-Hatta', 'Tebet'];
  }

  @override
  Future<List<RouteOption>> findOptions(TripRequest request) async {
    findCalls++;
    if (findGate != null) await findGate!.future;
    return options;
  }
}

Future<void> pumpScreen(WidgetTester tester, FakeRouteRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routeRepositoryProvider.overrideWithValue(repo),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 8, 0)),
      ],
      child: const MaterialApp(home: PlannerScreen()),
    ),
  );
}

Future<void> fillForm(WidgetTester tester, {required String time}) async {
  await tester.tap(find.byKey(const Key('originField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tebet').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('destinationField')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Bandara Soekarno-Hatta').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('arriveByField')), time);
}

void main() {
  testWidgets('initial loading: spinner tampil lalu form muncul', (tester) async {
    final repo = FakeRouteRepository()..placesGate = Completer<void>();
    await pumpScreen(tester, repo);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('searchButton')), findsNothing);

    repo.placesGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchButton')), findsOneWidget);
  });

  testWidgets('data berhasil dimuat: hasil rute ditampilkan', (tester) async {
    await pumpScreen(tester, FakeRouteRepository());
    await tester.pumpAndSettle();
    await fillForm(tester, time: '12:00');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();

    expect(find.text('Taksi online'), findsOneWidget);
    expect(find.text('Berangkat paling lambat 10:40'), findsOneWidget);
  });

  testWidgets('empty state: tidak ada opsi yang sempat dikejar', (tester) async {
    await pumpScreen(tester, FakeRouteRepository());
    await tester.pumpAndSettle();
    await fillForm(tester, time: '08:30');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyView), findsOneWidget);
  });

  testWidgets('error state: tombol Coba Lagi memuat ulang data', (tester) async {
    final repo = FakeRouteRepository()..placesError = Exception('gagal');
    await pumpScreen(tester, repo);
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    repo.placesError = null;
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchButton')), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('validasi: form kosong menampilkan pesan dan tidak mencari', (tester) async {
    final repo = FakeRouteRepository();
    await pumpScreen(tester, repo);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pump();

    expect(find.text('Asal wajib dipilih'), findsOneWidget);
    expect(find.text('Tujuan wajib dipilih'), findsOneWidget);
    expect(find.text('Jam tiba wajib diisi'), findsOneWidget);
    expect(repo.findCalls, 0);
  });

  testWidgets('validasi: jam tiba yang sudah lewat ditolak', (tester) async {
    final repo = FakeRouteRepository();
    await pumpScreen(tester, repo);
    await tester.pumpAndSettle();
    await fillForm(tester, time: '07:00');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pump();

    expect(find.text('Jam tiba sudah lewat'), findsOneWidget);
    expect(repo.findCalls, 0);
  });

  testWidgets('loading submit: tombol nonaktif dan tidak bisa double tap', (tester) async {
    final repo = FakeRouteRepository()..findGate = Completer<void>();
    await pumpScreen(tester, repo);
    await tester.pumpAndSettle();
    await fillForm(tester, time: '12:00');

    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('searchButton'))).onPressed, isNull);

    await tester.tap(find.byKey(const Key('searchButton')), warnIfMissed: false);
    await tester.pump();

    repo.findGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.findCalls, 1);
    expect(find.text('Taksi online'), findsOneWidget);
  });
}
