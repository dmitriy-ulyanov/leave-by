import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import 'auth_repository.dart';
import 'remote_auth_repository.dart';
import 'session_store.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) => SharedPrefsSessionStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return RemoteAuthRepository(client: client, baseUrl: apiBaseUrl);
});
