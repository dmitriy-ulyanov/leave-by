import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import 'local_saved_trip_repository.dart';
import 'remote_saved_trip_repository.dart';
import 'saved_trip_repository.dart';

final savedTripRepositoryProvider = Provider<SavedTripRepository>((ref) {
  if (storageMode == 'local') return LocalSavedTripRepository();
  final client = http.Client();
  ref.onDispose(client.close);
  return RemoteSavedTripRepository(client: client, baseUrl: apiBaseUrl);
});
