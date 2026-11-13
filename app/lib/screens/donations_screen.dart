import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../providers/profile_provider.dart';
import '../services/donation_service.dart';
import '../widgets/donation_card.dart';

/// Doador: lista das próprias doações, com filtro por status.
class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  DonationStatus? _filter;
  int _version = 0; // muda para forçar um novo carregamento

  void _refresh() => setState(() => _version++);

  Future<void> _newDonation() async {
    if (context.read<ProfileProvider>().donor == null) {
      showSnack(context, 'Complete seu cadastro antes de doar.');
      await context.push('/profile');
      return;
    }
    final created = await context.push<bool>('/donations/new');
    if (created == true && mounted) _refresh();
  }

  Future<void> _open(Donation d) async {
    await context.push('/donation/${d.id}');
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<DonationService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas doações')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newDonation,
        icon: const Icon(Icons.add),
        label: const Text('Nova doação'),
      ),
      body: ContentWidth(
        child: AsyncLoader<List<Donation>>(
          key: ValueKey(_version),
          load: service.listMine,
          builder: (context, donations, reload) {
            final visible = donations
                .where((d) => _filter == null || d.status == _filter)
                .toList();

            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Todas'),
                          selected: _filter == null,
                          onSelected: (_) => setState(() => _filter = null),
                        ),
                        for (final s in const [
                          DonationStatus.available,
                          DonationStatus.reserved,
                          DonationStatus.delivered,
                          DonationStatus.cancelled,
                        ]) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(s.label),
                            selected: _filter == s,
                            onSelected: (_) => setState(() => _filter = s),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: EmptyState(
                        icon: Icons.volunteer_activism_outlined,
                        message: 'Nenhuma doação por aqui ainda.',
                      ),
                    )
                  else
                    ResponsiveWrap(
                      children: [
                        for (final d in visible)
                          DonationCard(donation: d, onTap: () => _open(d)),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
