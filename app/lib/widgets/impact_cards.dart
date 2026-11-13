import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/responsive.dart';
import '../models/models.dart';

class ImpactCards extends StatelessWidget {
  final ImpactSummary summary;
  const ImpactCards(this.summary, {super.key});

  @override
  Widget build(BuildContext context) => ResponsiveWrap(
    minItemWidth: 200,
    children: [
      _Metric(
        icon: Icons.volunteer_activism,
        label: 'Doações registradas',
        value: '${summary.donationsCount}',
      ),
      _Metric(
        icon: Icons.check_circle_outline,
        label: 'Doações entregues',
        value: '${summary.deliveredCount}',
      ),
      _Metric(
        icon: Icons.recycling,
        label: 'Desperdício evitado',
        value: formatQuantity(summary.wasteAvoidedKg, 'kg'),
      ),
      _Metric(
        icon: Icons.groups_outlined,
        label: 'Pessoas atendidas',
        value: '${summary.peopleServed}',
      ),
      _Metric(
        icon: Icons.apartment_outlined,
        label: 'Instituições beneficiadas',
        value: '${summary.institutionsServed}',
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Metric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: theme.textTheme.headlineSmall),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
