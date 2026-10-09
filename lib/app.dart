import 'package:flutter/material.dart';

import 'features/planner/presentation/planner_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leave By',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PlannerScreen(),
    );
  }
}
