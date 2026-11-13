import 'package:flutter/material.dart';

import '../core/brand.dart';
import 'brand_logo.dart';

/// Layout das telas públicas (login e cadastro).
/// Celular: logo + formulário. Telas largas: painel da marca + formulário.
class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;

          final form = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!wide) ...[
                      const Center(child: BrandLogo(height: 64)),
                      const SizedBox(height: 32),
                    ],
                    Text(title, style: theme.textTheme.headlineSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          );

          if (!wide) return SafeArea(child: form);

          return Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  color: Brand.darkGreen,
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandLogo(height: 96, onDark: true),
                      const SizedBox(height: 24),
                      Text(
                        'Conectando quem tem alimento sobrando a quem precisa. '
                        'Menos desperdício, mais comida na mesa.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Brand.cream,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(flex: 4, child: form),
            ],
          );
        },
      ),
    );
  }
}
