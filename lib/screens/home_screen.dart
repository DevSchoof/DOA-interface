import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/institution_provider.dart';

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
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push('/admin/institutions'),
                icon: const Icon(Icons.fact_check),
                label: const Text('Homologar instituições'),
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
            if (user?.role == UserRole.institution) ...[
              const SizedBox(height: 24),
              _InstitutionSection(userId: user!.id),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mostra o botão de cadastro ou, se já cadastrada, o status da instituição.
class _InstitutionSection extends StatefulWidget {
  const _InstitutionSection({required this.userId});

  final String userId;

  @override
  State<_InstitutionSection> createState() => _InstitutionSectionState();
}

class _InstitutionSectionState extends State<_InstitutionSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstitutionProvider>().load(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InstitutionProvider>();
    final institution = provider.institution;

    if (institution == null) {
      if (provider.isLoading) return const CircularProgressIndicator();
      return FilledButton.icon(
        onPressed: () => context.push('/institutions/new'),
        icon: const Icon(Icons.apartment),
        label: const Text('Cadastrar instituição'),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              institution.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Chip(label: Text('Status: ${institution.status.label}')),
          ],
        ),
      ),
    );
  }
}
