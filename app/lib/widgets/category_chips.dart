import 'package:flutter/material.dart';

import '../core/presentation.dart';
import '../models/models.dart';

/// Seleção múltipla de categorias (usada no N:N instituição ↔ categoria).
class CategoryChips extends StatelessWidget {
  final List<FoodCategory> categories;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final c in categories)
        FilterChip(
          avatar: Icon(categoryIcon(c.name), size: 18),
          label: Text(c.name),
          selected: selected.contains(c.id),
          onSelected: (value) {
            final next = {...selected};
            value ? next.add(c.id) : next.remove(c.id);
            onChanged(next);
          },
        ),
    ],
  );
}
