import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/presentation.dart';
import '../models/models.dart';
import 'donation_photos.dart';
import 'pill.dart';

class DonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onTap;
  final bool showDonor;
  final bool showDistance;

  const DonationCard({
    super.key,
    required this.donation,
    required this.onTap,
    this.showDonor = false,
    this.showDistance = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = donation;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DonationPhotoCover(d.photoUrls),
            Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(child: Icon(categoryIcon(d.categoryName))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.categoryName, style: theme.textTheme.titleMedium),
                        Text(
                          d.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DonationStatusPill(d.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Info(Icons.scale_outlined, formatQuantity(d.quantity, d.unit)),
                  _Info(Icons.event_outlined, '${daysLabel(d.daysUntilExpiry)} (${formatDate(d.expiresAt)})'),
                  if (showDistance && d.distanceKm != null)
                    _Info(Icons.place_outlined, formatDistance(d.distanceKm!)),
                  if (showDonor) _Info(Icons.storefront_outlined, d.donorName),
                ],
              ),
              if (d.isPriority) ...[
                const SizedBox(height: 10),
                Pill(
                  label: 'Prioridade: validade curta',
                  icon: Icons.priority_high,
                  background: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                ),
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

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
      const SizedBox(width: 4),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}
