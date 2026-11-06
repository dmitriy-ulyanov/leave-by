import 'package:flutter/material.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/saved_trips/domain/saved_trip.dart';
import '../../features/saved_trips/presentation/saved_trip_form_screen.dart';
import '../../features/saved_trips/presentation/saved_trips_screen.dart';

class AppRoutes {
  static const String planner = '/';
  static const String register = '/register';
  static const String saved = '/saved';
  static const String savedForm = '/saved/form';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return MaterialPageRoute<void>(builder: (_) => const RegisterScreen(), settings: settings);
      case saved:
        return MaterialPageRoute<void>(builder: (_) => const SavedTripsScreen(), settings: settings);
      case savedForm:
        final trip = settings.arguments as SavedTrip?;
        return MaterialPageRoute<void>(builder: (_) => SavedTripFormScreen(initial: trip), settings: settings);
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthGate(child: PlannerScreen()),
          settings: settings,
        );
    }
  }
}
