import 'package:flutter/material.dart';

/// Pontos de quebra do layout.
/// - compact: celular (< 600): barra de navegação inferior
/// - medium: tablet (600 a 999): NavigationRail compacta
/// - expanded: desktop/web (>= 1000): NavigationRail estendida
class Breakpoints {
  static const double compact = 600;
  static const double expanded = 1000;
}

/// Limita a largura do conteúdo e centraliza em telas grandes.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({super.key, required this.child, this.maxWidth = 960});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Distribui os filhos em 1, 2, 3 ou 4 colunas conforme a largura disponível.
/// Não rola sozinho: use dentro de um ListView ou SingleChildScrollView.
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double minItemWidth;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 12,
    this.minItemWidth = 280,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth;
      final columns = ((available + spacing) / (minItemWidth + spacing))
          .floor()
          .clamp(1, 4)
          .toInt();
      final itemWidth = (available - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: itemWidth, child: child),
        ],
      );
    },
  );
}
