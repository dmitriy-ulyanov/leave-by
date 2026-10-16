import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave By',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      initialRoute: AppRoutes.planner,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
