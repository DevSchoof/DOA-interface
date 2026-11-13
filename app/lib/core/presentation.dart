import 'package:flutter/material.dart';

/// As categorias vêm da API (o admin pode criar novas), então o ícone é
/// escolhido pelo nome. Categoria desconhecida usa um ícone genérico.
IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('fruta')) return Icons.apple;
  if (n.contains('verdura') || n.contains('legume') || n.contains('horta')) {
    return Icons.eco;
  }
  if (n.contains('grão') || n.contains('grao') || n.contains('cereal')) {
    return Icons.grain;
  }
  if (n.contains('latic') || n.contains('leite')) return Icons.egg_alt;
  if (n.contains('carne') || n.contains('peixe')) return Icons.kebab_dining;
  if (n.contains('padaria') || n.contains('pão') || n.contains('pao')) {
    return Icons.bakery_dining;
  }
  if (n.contains('refei') || n.contains('marmita')) return Icons.restaurant;
  if (n.contains('bebida') || n.contains('suco')) return Icons.local_drink;
  return Icons.inventory_2;
}
