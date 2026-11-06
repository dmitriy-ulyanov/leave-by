import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../application/auth_form_notifiers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(loginFormProvider.notifier).submit(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (success) messenger.showSnackBar(const SnackBar(content: Text('Berhasil masuk.')));
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(loginFormProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Leave By', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  const Text('Masuk untuk melihat dan menyimpan perjalananmu.'),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('loginEmailField'),
                    controller: _emailController,
                    scrollPadding: formScrollPadding,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('loginPasswordField'),
                    controller: _passwordController,
                    scrollPadding: formScrollPadding,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!ref.read(loginFormProvider).isSubmitting) _submit();
                    },
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      suffixIcon: IconButton(
                        key: const Key('togglePasswordButton'),
                        tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.requiredPassword,
                  ),
                  if (form.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        form.errorMessage!,
                        key: const Key('authErrorText'),
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('loginSubmitButton'),
                    onPressed: form.isSubmitting ? null : _submit,
                    child: form.isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Memproses'))
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('goToRegisterButton'),
                    onPressed: form.isSubmitting ? null : () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
