import 'package:flutter/material.dart';

import '../models/models.dart';

class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class DonationStatusPill extends StatelessWidget {
  final DonationStatus status;
  const DonationStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      DonationStatus.available => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      DonationStatus.reserved => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      DonationStatus.delivered => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      DonationStatus.cancelled || DonationStatus.expired => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurface),
    };
    return Pill(label: status.label, background: bg, foreground: fg);
  }
}

class InstitutionStatusPill extends StatelessWidget {
  final InstitutionStatus status;
  const InstitutionStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      InstitutionStatus.approved => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      InstitutionStatus.pending => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      InstitutionStatus.rejected => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurface),
    };
    return Pill(label: status.label, background: bg, foreground: fg);
  }
}
