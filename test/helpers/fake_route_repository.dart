import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/features/planner/data/route_repository.dart';
import 'package:leave_by/features/planner/domain/route_option.dart';
import 'package:leave_by/features/planner/domain/transport_mode.dart';
import 'package:leave_by/features/planner/domain/trip_request.dart';

const taxiOption = RouteOption(
  id: 'taxi',
  mode: TransportMode.taksiOnline,
  label: 'Taksi online',
  travelMinutes: 60,
  transitCount: 0,
  costRupiah: 250000,
);

class FakeRouteRepository implements RouteRepository {
  FakeRouteRepository({this.options = const [taxiOption]});

  final List<RouteOption> options;
  Completer<void>? findGate;

  @override
  Future<List<String>> loadPlaces() async => const ['Bandara Soekarno-Hatta', 'Tebet'];

  @override
  Future<List<RouteOption>> findOptions(TripRequest request) async {
    if (findGate != null) await findGate!.future;
    return options;
  }
}

Future<void> fillPlannerForm(WidgetTester tester, {String time = '12:00'}) async {
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
