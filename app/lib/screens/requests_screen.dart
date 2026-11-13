import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../services/donation_service.dart';
import '../widgets/donation_card.dart';

/// Instituição: doações reservadas (aguardando coleta) e já recebidas.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _version = 0;

  Future<void> _open(Donation d) async {
    await context.push('/donation/${d.id}');
    if (mounted) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<DonationService>();
    final theme = Theme.of(context);

    List<Widget> section(String title, List<Donation> items) => items.isEmpty
        ? []
        : [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            ResponsiveWrap(
              children: [
                for (final d in items)
                  DonationCard(donation: d, showDonor: true, onTap: () => _open(d)),
              ],
            ),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitações')),
      body: ContentWidth(
        child: AsyncLoader<List<Donation>>(
          key: ValueKey(_version),
          load: service.listRequested,
          builder: (context, donations, reload) {
            if (donations.isEmpty) {
              return const EmptyState(
                icon: Icons.assignment_outlined,
                message: 'Você ainda não solicitou nenhuma doação.',
              );
            }
            final waiting = donations
                .where((d) => d.status == DonationStatus.reserved)
                .toList();
            final others = donations
                .where((d) => d.status != DonationStatus.reserved)
                .toList();
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  ...section('Aguardando coleta (${waiting.length}/5)', waiting),
                  ...section('Histórico', others),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
