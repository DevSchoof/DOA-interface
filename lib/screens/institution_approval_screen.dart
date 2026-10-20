import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/institution_service.dart';

/// PB-007: o administrador homologa ou rejeita instituições pendentes.
class InstitutionApprovalScreen extends StatefulWidget {
  const InstitutionApprovalScreen({super.key});

  @override
  State<InstitutionApprovalScreen> createState() =>
      _InstitutionApprovalScreenState();
}

class _InstitutionApprovalScreenState extends State<InstitutionApprovalScreen> {
  List<Institution>? _pending;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<InstitutionService>().listByStatus(
        InstitutionStatus.pending,
      );
      if (mounted) setState(() => _pending = list);
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível carregar.');
    }
  }

  Future<void> _decide(Institution item, InstitutionStatus status) async {
    final service = context.read<InstitutionService>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = item.id);
    try {
      await service.updateStatus(item.id, status);
      if (!mounted) return;
      setState(
        () => _pending = _pending!.where((i) => i.id != item.id).toList(),
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == InstitutionStatus.approved
                ? '${item.name} foi homologada.'
                : '${item.name} foi rejeitada.',
          ),
        ),
      );
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível concluir a ação.')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  String _formatCnpj(String d) => d.length == 14
      ? '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
            '${d.substring(8, 12)}-${d.substring(12)}'
      : d;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homologação de instituições')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) return Text(_error!);
    final pending = _pending;
    if (pending == null) return const CircularProgressIndicator();
    if (pending.isEmpty) {
      return const Text('Nenhuma instituição pendente.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final item = pending[index];
        final busy = _busyId == item.id;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('CNPJ: ${_formatCnpj(item.cnpj)}'),
                Text('${item.address} - ${item.city}'),
                Text('Capacidade: ${item.storageCapacity.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: busy
                          ? null
                          : () => _decide(item, InstitutionStatus.rejected),
                      child: const Text('Rejeitar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: busy
                          ? null
                          : () => _decide(item, InstitutionStatus.approved),
                      child: const Text('Aprovar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
