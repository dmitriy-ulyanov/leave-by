import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/api_config.dart';
import 'core/routes/app_routes.dart';
import 'features/auth/application/auth_notifier.dart';
import 'features/auth/domain/auth_session.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthSession?>>(authProvider, (previous, next) {
      if (previous?.value?.userId != next.value?.userId) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
    return MaterialApp(
      title: 'Leave By',
      navigatorKey: _navigatorKey,
      showSemanticsDebugger: showSemanticsOverlay,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: AppRoutes.planner,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
