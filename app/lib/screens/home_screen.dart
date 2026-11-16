import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/responsive.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/impact_service.dart';
import '../services/institution_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/impact_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profile = context.watch<ProfileProvider>();
    final impact = context.read<ImpactService>();
    final theme = Theme.of(context);
    final role = user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const BrandLogo(height: 28),
        actions: [
          if (role == UserRole.donor || role == UserRole.institution)
            IconButton(
              tooltip: 'Meu cadastro',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => context.push('/profile'),
            ),
          // Em telas largas o botão "Sair" fica na NavigationRail.
          if (MediaQuery.sizeOf(context).width < Breakpoints.compact)
            IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Olá, ${_displayName(profile, role)}', style: theme.textTheme.titleLarge),
            Text(role?.label ?? '', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (profile.isLoading)
              const LinearProgressIndicator()
            else ...[
              if (role == UserRole.donor) _DonorSection(profile: profile),
              if (role == UserRole.institution)
                _InstitutionSection(profile: profile),
              if (role == UserRole.admin) const _AdminSection(),
            ],
            const SizedBox(height: 24),
            Text('Seu impacto', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            AsyncLoader<ImpactSummary>(
              load: impact.getSummary,
              builder: (context, summary, _) => ImpactCards(summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const _Banner({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color ?? theme.colorScheme.secondaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(message),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorSection extends StatelessWidget {
  final ProfileProvider profile;
  const _DonorSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.donor == null) {
      return _Banner(
        icon: Icons.assignment_ind_outlined,
        title: 'Complete seu cadastro',
        message: 'Precisamos de alguns dados para você começar a doar.',
        actionLabel: 'Completar cadastro',
        onAction: () => context.push('/profile'),
      );
    }
    return FilledButton.icon(
      onPressed: () => context.push('/donations/new'),
      icon: const Icon(Icons.add),
      label: const Text('Nova doação'),
    );
  }
}

class _InstitutionSection extends StatelessWidget {
  final ProfileProvider profile;
  const _InstitutionSection({required this.profile});

  @override
  Widget build(BuildContext context) {
    final institution = profile.institution;
    if (institution == null) {
      return _Banner(
        icon: Icons.assignment_ind_outlined,
        title: 'Complete o cadastro da instituição',
        message: 'Envie os dados da instituição para análise do administrador.',
        actionLabel: 'Completar cadastro',
        onAction: () => context.push('/profile'),
      );
    }
    return switch (institution.status) {
      InstitutionStatus.pending => const _Banner(
        icon: Icons.hourglass_top,
        title: 'Cadastro em análise',
        message:
            'O administrador analisa o cadastro em até 24 horas. Você poderá '
            'buscar doações assim que for aprovado.',
      ),
      InstitutionStatus.rejected => _Banner(
        icon: Icons.block,
        title: 'Cadastro rejeitado',
        message: institution.rejectionReason ?? 'Entre em contato com o administrador.',
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      _ => FilledButton.icon(
        onPressed: () => context.go('/search'),
        icon: const Icon(Icons.search),
        label: const Text('Buscar doações'),
      ),
    };
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection();

  @override
  Widget build(BuildContext context) {
    final service = context.read<InstitutionService>();
    return AsyncLoader<List<Institution>>(
      load: () => service.listByStatus(InstitutionStatus.pending),
      builder: (context, pending, _) => _Banner(
        icon: Icons.apartment,
        title: pending.isEmpty
            ? 'Nenhuma instituição aguardando'
            : '${pending.length} instituição(ões) aguardando aprovação',
        message: 'Valide o CNPJ e libere o acesso das instituições.',
        actionLabel: pending.isEmpty ? null : 'Analisar agora',
        onAction: () => context.go('/admin/institutions'),
      ),
    );
  }
}

/// Nome para a saudação: doador/instituição usam o nome do cadastro; o admin não tem perfil.
String _displayName(ProfileProvider profile, UserRole? role) {
  final name = profile.donor?.name ?? profile.institution?.name;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return role == UserRole.admin ? 'Administrador' : '';
}
