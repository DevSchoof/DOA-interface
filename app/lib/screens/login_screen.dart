import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().clearError();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Em caso de sucesso, o router redireciona sozinho para /home.
    await context.read<AuthProvider>().login(
      _emailController.text,
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      title: 'Entrar',
      subtitle: 'Combate à fome e ao desperdício de alimentos',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => validateRequired(v, 'Informe a senha.'),
              onFieldSubmitted: (_) => _submit(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: auth.isLoading ? null : () => context.go('/register'),
              child: const Text('Não tem conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}
