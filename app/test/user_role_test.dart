import 'package:doa_interface/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole.fromString', () {
    test('aceita maiúsculas e minúsculas', () {
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('donor'), UserRole.donor);
    });

    test('valor desconhecido ou nulo vira unknown', () {
      expect(UserRole.fromString('outro'), UserRole.unknown);
      expect(UserRole.fromString(null), UserRole.unknown);
    });
  });
}
