import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/core/providers/clock_provider.dart';
import 'package:leave_by/core/routes/app_routes.dart';
import 'package:leave_by/features/saved_trips/data/saved_trip_providers.dart';
import 'package:leave_by/features/saved_trips/data/saved_trip_repository.dart';
import 'package:leave_by/features/saved_trips/presentation/saved_trips_screen.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  SavedTripRepository? repository,
  Widget home = const SavedTripsScreen(),
  List<Override> extraOverrides = const [],
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null) savedTripRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 8, 0)),
        ...extraOverrides,
      ],
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    ),
  );
}

Future<void> fillTripForm(
  WidgetTester tester, {
  String title = 'Ke bandara',
  String origin = 'Tebet',
  String destination = 'Bandara Soekarno-Hatta',
  String time = '12:00',
  String note = '',
}) async {
  await tester.enterText(find.byKey(const Key('tripTitleField')), title);
  await tester.enterText(find.byKey(const Key('tripOriginField')), origin);
  await tester.enterText(find.byKey(const Key('tripDestinationField')), destination);
  await tester.enterText(find.byKey(const Key('tripArriveByField')), time);
  if (note.isNotEmpty) {
    await tester.enterText(find.byKey(const Key('tripNoteField')), note);
  }
}
