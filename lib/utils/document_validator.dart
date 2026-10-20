/// Remove tudo que não for dígito.
String onlyDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

bool isValidCpf(String input) {
  final d = onlyDigits(input);
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

bool isValidCnpj(String input) {
  final d = onlyDigits(input);
  if (d.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;

  int check(List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += int.parse(d[i]) * weights[i];
    }
    final r = sum % 11;
    return r < 2 ? 0 : 11 - r;
  }

  const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  return check(w1) == int.parse(d[12]) && check(w2) == int.parse(d[13]);
}
