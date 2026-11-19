import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.isWeb = kIsWeb});

  final bool isWeb;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Nosso Mercado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre com sua conta autorizada para acessar o mercado, '
                    'criar sua casa e organizar compras.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('auth-email'),
                    controller: _emailController,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('auth-display-name'),
                    controller: _displayNameController,
                    enabled: !_busy,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome de usuário (opcional)',
                      prefixIcon: Icon(Icons.person_outline),
                      helperText:
                          'Se vazio, usaremos a parte do e-mail antes do @.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('auth-password'),
                    controller: _passwordController,
                    enabled: !_busy,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscurePassword
                            ? 'Mostrar senha'
                            : 'Ocultar senha',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('auth-sign-in'),
                    onPressed: _busy ? null : _signIn,
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('auth-register'),
                    onPressed: _busy ? null : _register,
                    child: const Text('Criar conta autorizada'),
                  ),
                  const SizedBox(height: 4),
                  if (widget.isWeb)
                    TextButton(
                      key: const Key('auth-forgot-password'),
                      onPressed: _busy ? null : _sendPasswordResetEmail,
                      child: const Text('Esqueci minha senha'),
                    )
                  else
                    Text(
                      'Para redefinir a senha, use o site do Nosso Mercado. '
                      'Essa opção ainda não está disponível neste aplicativo.',
                      key: const Key('auth-forgot-password-unavailable'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() => _run(
    () => ref
        .read(cloudAuthServiceProvider)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        ),
  );

  Future<void> _register() => _run(
    () => ref
        .read(cloudAuthServiceProvider)
        .register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _displayNameController.text,
        ),
  );

  Future<void> _sendPasswordResetEmail() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(cloudAuthServiceProvider)
          .sendPasswordResetEmail(email: _emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se o e-mail tiver uma conta, enviaremos as instruções para '
              'redefinir a senha.',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível continuar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível continuar: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}
