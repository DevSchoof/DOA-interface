/// Validação dos dígitos verificadores. Recebe só dígitos.
bool isValidCpf(String d) {
  if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
  int check(int length) {
    var sum = 0;
    for (var i = 0; i < length; i++) {
      sum += int.parse(d[i]) * (length + 1 - i);
    }
    final r = (sum * 10) % 11;
    return r == 10 ? 0 : r;
  }

  return check(9) == int.parse(d[9]) && check(10) == int.parse(d[10]);
}

bool isValidCnpj(String d) {
  if (d.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;
  int check(List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += int.parse(d[i]) * weights[i];
    }
    final r = sum % 11;
    return r < 2 ? 0 : 11 - r;
  }

  return check([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == int.parse(d[12]) &&
      check([6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) == int.parse(d[13]);
}

String? validateRequired(String? value, String message) =>
    (value == null || value.trim().isEmpty) ? message : null;

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Informe o e-mail.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'E-mail inválido.';
  }
  return null;
}
