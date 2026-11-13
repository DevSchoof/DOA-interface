String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String formatQuantity(double q, String unit) {
  final text = q == q.roundToDouble()
      ? q.toStringAsFixed(0)
      : q.toStringAsFixed(1).replaceAll('.', ',');
  return '$text $unit';
}

String formatDistance(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

String onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Formata CPF (11 dígitos) ou CNPJ (14 dígitos). Outros tamanhos voltam iguais.
String formatDocument(String d) {
  if (d.length == 11) {
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }
  if (d.length == 14) {
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }
  return d;
}

String daysLabel(int days) {
  if (days < 0) return 'vencida';
  if (days == 0) return 'vence hoje';
  if (days == 1) return 'vence amanhã';
  return 'vence em $days dias';
}

/// Data no formato que a API espera (yyyy-MM-dd).
String toApiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';
