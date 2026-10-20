import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dôa'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Olá, ${user?.email}'),
            Text('Perfil: ${user?.role.label}'),
            if (user?.role == UserRole.admin) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/users/new'),
                icon: const Icon(Icons.person_add),
                label: const Text('Cadastrar usuário'),
              ),
            ],
            if (user?.role == UserRole.donor) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/donors/new'),
                icon: const Icon(Icons.volunteer_activism),
                label: const Text('Cadastrar dados de doador'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
