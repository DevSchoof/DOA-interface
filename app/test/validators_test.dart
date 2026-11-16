import 'package:doa_interface/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CPF válido e inválidos', () {
    expect(isValidCpf('52998224725'), isTrue);
    expect(isValidCpf('52998224726'), isFalse);
    expect(isValidCpf('11111111111'), isFalse);
    expect(isValidCpf('123'), isFalse);
  });

  test('CNPJ válido e inválidos', () {
    expect(isValidCnpj('11222333000181'), isTrue);
    expect(isValidCnpj('11222333000182'), isFalse);
    expect(isValidCnpj('00000000000000'), isFalse);
  });

  test('e-mail', () {
    expect(validateEmail('a@b.com'), isNull);
    expect(validateEmail('a@b'), isNotNull);
    expect(validateEmail(''), isNotNull);
  });
}
