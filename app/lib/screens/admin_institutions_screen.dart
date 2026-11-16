import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/format.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/institution_service.dart';
import '../widgets/pill.dart';

/// RF03 e RF17: administrador aprova ou rejeita cadastros de instituições.
class AdminInstitutionsScreen extends StatefulWidget {
  const AdminInstitutionsScreen({super.key});

  @override
  State<AdminInstitutionsScreen> createState() => _AdminInstitutionsScreenState();
}

class _AdminInstitutionsScreenState extends State<AdminInstitutionsScreen> {
  InstitutionStatus _status = InstitutionStatus.pending;
  int _version = 0;

  Future<void> _decide(
    Future<Institution> Function() action,
    String okMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      showSnack(context, okMessage);
      setState(() => _version++);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, 'Não foi possível concluir. Tente novamente.');
    }
  }

  Future<void> _reject(Institution i, InstitutionService service) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar cadastro'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Justificativa'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    await _decide(() => service.reject(i.id, reason), 'Cadastro rejeitado.');
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<InstitutionService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Instituições')),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<InstitutionStatus>(
                segments: const [
                  ButtonSegment(
                    value: InstitutionStatus.pending,
                    label: Text('Em análise'),
                  ),
                  ButtonSegment(
                    value: InstitutionStatus.approved,
                    label: Text('Aprovadas'),
                  ),
                  ButtonSegment(
                    value: InstitutionStatus.rejected,
                    label: Text('Rejeitadas'),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
            ),
            Expanded(
              child: AsyncLoader<List<Institution>>(
                key: ValueKey('$_status-$_version'),
                load: () => service.listByStatus(_status),
                builder: (context, items, reload) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.apartment_outlined,
                      message: 'Nenhuma instituição nesta lista.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        ResponsiveWrap(
                          minItemWidth: 360,
                          children: [
                            for (final i in items)
                              _InstitutionCard(
                                institution: i,
                                onApprove: () => _decide(
                                  () => service.approve(i.id),
                                  'Instituição aprovada.',
                                ),
                                onReject: () => _reject(i, service),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  final Institution institution;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _InstitutionCard({
    required this.institution,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i = institution;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(i.name, style: theme.textTheme.titleMedium)),
                InstitutionStatusPill(i.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('CNPJ ${formatDocument(i.cnpj)}'),
            Text('${i.address}, ${i.city}'),
            Text('Atuação: ${i.areaOfActivity}'),
            Text('Capacidade: ${formatQuantity(i.storageCapacityKg, 'kg')}'),
            if (i.categories.isNotEmpty)
              Text('Aceita: ${i.categories.map((c) => c.name).join(', ')}'),
            if (i.rejectionReason != null) Text('Justificativa: ${i.rejectionReason}'),
            if (i.status == InstitutionStatus.pending) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Aprovar'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeitar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
