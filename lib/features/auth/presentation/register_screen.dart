import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/utils/validators.dart';
import '../application/auth_form_notifiers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(registerFormProvider.notifier).submit(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!success) return;
    messenger.showSnackBar(const SnackBar(content: Text('Akun dibuat. Selamat datang!')));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(registerFormProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
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
                  TextFormField(
                    key: const Key('registerNameField'),
                    controller: _nameController,
                    scrollPadding: formScrollPadding,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: Validators.personName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('registerEmailField'),
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
                    key: const Key('registerPasswordField'),
                    controller: _passwordController,
                    scrollPadding: formScrollPadding,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi (minimal 8 karakter)',
                      suffixIcon: IconButton(
                        key: const Key('registerTogglePasswordButton'),
                        tooltip: _obscure ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('registerConfirmField'),
                    controller: _confirmController,
                    scrollPadding: formScrollPadding,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!ref.read(registerFormProvider).isSubmitting) _submit();
                    },
                    decoration: const InputDecoration(labelText: 'Ulangi kata sandi'),
                    validator: (value) => Validators.confirmPassword(value, _passwordController.text),
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
                    key: const Key('registerSubmitButton'),
                    onPressed: form.isSubmitting ? null : _submit,
                    child: form.isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, semanticsLabel: 'Memproses'))
                        : const Text('Daftar'),
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
