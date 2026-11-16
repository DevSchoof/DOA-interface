import 'package:flutter/material.dart';

/// Logomarca do Dôa. Troca sozinha entre a versão para fundo claro e a de
/// fundo escuro conforme o tema. Com `mark: true`, mostra só o símbolo.
class BrandLogo extends StatelessWidget {
  final double height;
  final bool mark;

  /// Força a versão clara (creme) mesmo no tema claro, para usar sobre fundos
  /// escuros fixos, como o painel verde da tela de login.
  final bool onDark;

  const BrandLogo({
    super.key,
    this.height = 48,
    this.mark = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = onDark || Theme.of(context).brightness == Brightness.dark;
    final name = mark
        ? (dark ? 'logo_mark_light' : 'logo_mark')
        : (dark ? 'logo_dark' : 'logo');
    return Image.asset(
      'assets/images/$name.png',
      height: height,
      semanticLabel: 'Dôa',
      filterQuality: FilterQuality.medium,
    );
  }
}
