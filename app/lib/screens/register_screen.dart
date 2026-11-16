import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

/// Cadastro público (RF01 e RF02): cria a conta e já entra no app.
/// Depois, a tela de perfil pede os dados de doador ou instituição.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  UserRole _role = UserRole.donor;
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
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().signUp(
      _emailController.text,
      _passwordController.text,
      _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthLayout(
      title: 'Criar conta',
      subtitle: 'Escolha como você quer participar',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(
                  value: UserRole.donor,
                  icon: Icon(Icons.volunteer_activism),
                  label: Text('Doador'),
                ),
                ButtonSegment(
                  value: UserRole.institution,
                  icon: Icon(Icons.apartment),
                  label: Text('Instituição'),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _role == UserRole.donor
                  ? 'Para pessoas, mercados, restaurantes e produtores que querem doar.'
                  : 'Para ONGs e grupos que recebem e distribuem alimentos. '
                        'O cadastro passa por aprovação do administrador.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Senha',
                helperText: 'Mínimo de 6 caracteres',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a senha.';
                if (v.length < 6) return 'A senha deve ter ao menos 6 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
              validator: (v) =>
                  v != _passwordController.text ? 'As senhas não conferem.' : null,
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
                  : const Text('Criar conta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: auth.isLoading ? null : () => context.go('/login'),
              child: const Text('Já tenho conta'),
            ),
          ],
        ),
      ),
    );
  }
}
