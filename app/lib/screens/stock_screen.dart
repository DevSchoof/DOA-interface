import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/format.dart';
import '../core/presentation.dart';
import '../core/responsive.dart';
import '../core/state_views.dart';
import '../models/models.dart';
import '../services/stock_service.dart';

/// CSU06: estoque da instituição com alerta ao atingir 80% da validade.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<StockService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Estoque')),
      body: ContentWidth(
        child: AsyncLoader<List<StockItem>>(
          load: service.listStock,
          builder: (context, items, reload) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory_2_outlined,
                message: 'Seu estoque está vazio. Confirme o recebimento de '
                    'doações para abastecê-lo.',
              );
            }
            final alerts = items.where((i) => i.isNearExpiry).length;
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (alerts > 0) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.errorContainer,
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        title: Text(
                          '$alerts item(ns) perto da validade',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                        subtitle: Text(
                          'Priorize o uso ou a distribuição desses alimentos.',
                          style: TextStyle(color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ResponsiveWrap(children: [for (final i in items) _StockCard(i)]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockItem item;
  const _StockCard(this.item);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warn = item.isNearExpiry;
    final color = warn ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(categoryIcon(item.categoryName))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description, style: theme.textTheme.titleMedium),
                      Text(
                        '${formatQuantity(item.quantity, item.unit)} · ${item.categoryName}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: item.validityUsed,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              '${(item.validityUsed * 100).round()}% da validade · vence em ${formatDate(item.expiresAt)}',
              style: theme.textTheme.bodySmall?.copyWith(color: warn ? color : null),
            ),
          ],
        ),
      ),
    );
  }
}
