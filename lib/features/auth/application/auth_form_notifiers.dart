import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_providers.dart';
import 'auth_notifier.dart';

class AuthFormState {
  const AuthFormState({this.isSubmitting = false, this.errorMessage});

  final bool isSubmitting;
  final String? errorMessage;
}

final loginFormProvider =
    NotifierProvider.autoDispose<LoginFormNotifier, AuthFormState>(LoginFormNotifier.new);

final registerFormProvider =
    NotifierProvider.autoDispose<RegisterFormNotifier, AuthFormState>(RegisterFormNotifier.new);

class LoginFormNotifier extends AutoDisposeNotifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  Future<bool> submit({required String email, required String password}) async {
    if (state.isSubmitting) return false;
    state = const AuthFormState(isSubmitting: true);
    try {
      final session = await ref.read(authRepositoryProvider).login(email: email.trim(), password: password);
      state = const AuthFormState();
      await ref.read(authProvider.notifier).signIn(session);
      return true;
    } catch (error) {
      final message = error is ApiException ? error.message : 'Gagal masuk. Coba lagi.';
      state = AuthFormState(errorMessage: message);
      return false;
    }
  }
}

class RegisterFormNotifier extends AutoDisposeNotifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  Future<bool> submit({required String name, required String email, required String password}) async {
    if (state.isSubmitting) return false;
    state = const AuthFormState(isSubmitting: true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .register(name: name.trim(), email: email.trim(), password: password);
      state = const AuthFormState();
      await ref.read(authProvider.notifier).signIn(session);
      return true;
    } catch (error) {
      final message = error is ApiException ? error.message : 'Gagal mendaftar. Coba lagi.';
      state = AuthFormState(errorMessage: message);
      return false;
    }
  }
}
