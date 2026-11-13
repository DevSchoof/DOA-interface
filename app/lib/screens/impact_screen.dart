import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/async_loader.dart';
import '../core/responsive.dart';
import '../models/models.dart';
import '../services/impact_service.dart';
import '../widgets/impact_cards.dart';

/// RF16: métricas de impacto social.
class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<ImpactService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Impacto social')),
      body: ContentWidth(
        child: AsyncLoader<ImpactSummary>(
          load: service.getSummary,
          builder: (context, summary, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                ImpactCards(summary),
                const SizedBox(height: 16),
                Text(
                  'Estimativa: cada 500 g de alimento entregue equivale a uma '
                  'refeição para uma pessoa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
