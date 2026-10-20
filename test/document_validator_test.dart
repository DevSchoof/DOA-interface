import 'package:doa_interface/utils/document_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onlyDigits remove a máscara', () {
    expect(onlyDigits('529.982.247-25'), '52998224725');
  });

  group('CPF', () {
    test('aceita CPF válido, com ou sem máscara', () {
      expect(isValidCpf('529.982.247-25'), isTrue);
      expect(isValidCpf('52998224725'), isTrue);
    });

    test('rejeita dígito verificador errado, repetidos e tamanho errado', () {
      expect(isValidCpf('529.982.247-24'), isFalse);
      expect(isValidCpf('111.111.111-11'), isFalse);
      expect(isValidCpf('123'), isFalse);
    });
  });

  group('CNPJ', () {
    test('aceita CNPJ válido, com ou sem máscara', () {
      expect(isValidCnpj('11.222.333/0001-81'), isTrue);
      expect(isValidCnpj('11222333000181'), isTrue);
    });

    test('rejeita dígito verificador errado, repetidos e tamanho errado', () {
      expect(isValidCnpj('11.222.333/0001-80'), isFalse);
      expect(isValidCnpj('11.111.111/1111-11'), isFalse);
      expect(isValidCnpj('123'), isFalse);
    });
  });
}
