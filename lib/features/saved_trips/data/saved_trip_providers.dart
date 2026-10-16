import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_saved_trip_repository.dart';
import 'saved_trip_repository.dart';

final savedTripRepositoryProvider = Provider<SavedTripRepository>((ref) => LocalSavedTripRepository());
