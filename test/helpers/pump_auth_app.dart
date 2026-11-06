import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leave_by/core/providers/clock_provider.dart';
import 'package:leave_by/core/routes/app_routes.dart';
import 'package:leave_by/features/auth/data/auth_providers.dart';
import 'package:leave_by/features/auth/presentation/auth_gate.dart';

import 'fake_auth_repository.dart';

const homeMarker = 'Beranda';

Future<void> pumpAuthApp(
  WidgetTester tester, {
  required FakeAuthRepository repository,
  required InMemorySessionStore store,
  Widget child = const Scaffold(body: Center(child: Text(homeMarker))),
  List<Override> extraOverrides = const [],
  Size size = const Size(800, 1600),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        sessionStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 8, 0)),
        ...extraOverrides,
      ],
      child: MaterialApp(
        home: AuthGate(child: child),
        onGenerateRoute: AppRoutes.onGenerateRoute,
        builder: (context, appChild) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: appChild!,
        ),
      ),
    ),
  );
}
