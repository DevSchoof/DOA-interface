import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/donation_photos.dart';
import '../core/async_loader.dart';
import '../core/format.dart';
import '../core/presentation.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_exception.dart';
import '../services/donation_service.dart';
import '../widgets/pill.dart';

/// Detalhe da doação. As ações dependem do perfil:
/// doador dono cancela; instituição aprovada solicita; quem reservou confirma recebimento.
class DonationDetailScreen extends StatelessWidget {
  final String id;
  const DonationDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final service = context.read<DonationService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da doação')),
      body: ContentWidth(
        maxWidth: 700,
        child: AsyncLoader<Donation>(
          load: () => service.getById(id),
          builder: (context, donation, reload) =>
              _DetailBody(donation: donation, onChanged: reload),
        ),
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final Donation donation;
  final Future<void> Function() onChanged;
  const _DetailBody({required this.donation, required this.onChanged});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  bool _busy = false;

  Future<void> _run(Future<Donation> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showSnack(context, okMessage);
      widget.onChanged();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível concluir. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Donation d) async {
    final service = context.read<DonationService>();
    final ok = await confirmDialog(
      context,
      title: 'Excluir doação?',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    try {
      await service.deleteDonation(d.id);
      if (!mounted) return;
      showSnack(context, 'Doação excluída.');
      context.pop();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível excluir. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.donation;
    final theme = Theme.of(context);
    final service = context.read<DonationService>();
    final role = context.watch<AuthProvider>().user?.role;
    final profile = context.watch<ProfileProvider>();

    final isOwner = role == UserRole.donor && d.donorId == profile.donor?.id;
    final isReserver = role == UserRole.institution &&
        d.reservedById != null &&
        d.reservedById == profile.institution?.id;
    final canRequest = role == UserRole.institution &&
        profile.isInstitutionApproved &&
        d.status == DonationStatus.available;
    final canCancel = isOwner &&
        (d.status == DonationStatus.available ||
            d.status == DonationStatus.reserved);
    final canConfirm = isReserver && d.status == DonationStatus.reserved;
    final canEdit = isOwner && d.status == DonationStatus.available;
    final canDelete = isOwner &&
        (d.status == DonationStatus.available ||
            d.status == DonationStatus.cancelled ||
            d.status == DonationStatus.expired);
    final canChat = (isOwner || isReserver) &&
        (d.status == DonationStatus.reserved ||
            d.status == DonationStatus.delivered);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (d.photoUrls.isNotEmpty) ...[
          DonationPhotoGallery(d.photoUrls),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            CircleAvatar(radius: 28, child: Icon(categoryIcon(d.categoryName), size: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.categoryName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  DonationStatusPill(d.status),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(d.description, style: theme.textTheme.bodyLarge),
        if (d.isPriority) ...[
          const SizedBox(height: 12),
          Pill(
            label: 'Prioridade: ${daysLabel(d.daysUntilExpiry)}',
            icon: Icons.priority_high,
            background: theme.colorScheme.errorContainer,
            foreground: theme.colorScheme.onErrorContainer,
          ),
        ],
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Line(Icons.scale_outlined, 'Quantidade', formatQuantity(d.quantity, d.unit)),
                _Line(Icons.event_outlined, 'Validade', '${formatDate(d.expiresAt)} (${daysLabel(d.daysUntilExpiry)})'),
                if (d.storageConditions != null)
                  _Line(Icons.thermostat, 'Armazenamento', d.storageConditions!),
                _Line(Icons.storefront_outlined, 'Doador', d.donorName),
                _Line(Icons.place_outlined, 'Cidade', d.city),
                if (d.distanceKm != null && role == UserRole.institution)
                  _Line(Icons.near_me_outlined, 'Distância', formatDistance(d.distanceKm!)),
                if (d.reservedByName != null)
                  _Line(Icons.apartment_outlined, 'Reservada por', d.reservedByName!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (canChat) ...[
          FilledButton.tonalIcon(
            onPressed: () => context.push('/donation/${d.id}/chat'),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Conversar'),
          ),
          const SizedBox(height: 8),
        ],
        if (canRequest)
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                    () => service.requestDonation(d.id),
                    'Doação reservada! Combine a coleta com o doador.',
                  ),
            icon: const Icon(Icons.front_hand_outlined),
            label: const Text('Solicitar doação'),
          ),
        if (canConfirm)
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(
                    () => service.confirmDelivery(d.id),
                    'Recebimento confirmado. Itens adicionados ao estoque.',
                  ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirmar recebimento'),
          ),
        if (canCancel) ...[
          if (canRequest || canConfirm) const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'Cancelar doação?',
                      message: 'A doação deixará de aparecer para as instituições.',
                      confirmLabel: 'Cancelar doação',
                    );
                    if (ok) {
                      await _run(
                        () => service.cancelDonation(d.id),
                        'Doação cancelada.',
                      );
                    }
                  },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar doação'),
          ),
        ],
        if (canEdit) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final changed = await context.push<bool>(
                      '/donation/${d.id}/edit',
                      extra: d,
                    );
                    if (changed == true) widget.onChanged();
                  },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar doação'),
          ),
        ],
        if (canDelete) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _busy ? null : () => _delete(d),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir doação'),
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Line(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
