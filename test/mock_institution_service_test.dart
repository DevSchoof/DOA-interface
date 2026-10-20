import 'package:doa_interface/models/models.dart';
import 'package:doa_interface/services/auth_service.dart';
import 'package:doa_interface/services/mock_institution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockInstitutionService service;

  setUp(() => service = MockInstitutionService());

  Future<Institution> register({
    String userId = 'u3',
    String cnpj = '11222333000181',
    double capacity = 500,
  }) => service.registerInstitution(
    userId: userId,
    name: 'ONG Esperança',
    cnpj: cnpj,
    phone: '11999998888',
    address: 'Rua A, 10',
    city: 'São Paulo',
    storageCapacity: capacity,
  );

  test('cadastra instituição com status pendente', () async {
    final i = await register();
    expect(i.userId, 'u3');
    expect(i.status, InstitutionStatus.pending);
    expect(i.isApproved, isFalse);
  });

  test('rejeita CNPJ repetido', () async {
    await register();
    expect(register(userId: 'u9'), throwsA(isA<AuthException>()));
  });

  test('rejeita segunda instituição do mesmo usuário', () async {
    await register();
    expect(register(cnpj: '11444777000161'), throwsA(isA<AuthException>()));
  });

  test('rejeita capacidade zero ou negativa', () {
    expect(register(capacity: 0), throwsA(isA<AuthException>()));
  });

  test('findByUserId retorna a instituição ou null', () async {
    expect(await service.findByUserId('u3'), isNull);
    final created = await register();
    final found = await service.findByUserId('u3');
    expect(found?.id, created.id);
  });
}
