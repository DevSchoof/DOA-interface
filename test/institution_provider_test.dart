import 'package:doa_interface/models/models.dart';
import 'package:doa_interface/providers/institution_provider.dart';
import 'package:doa_interface/services/mock_institution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('register guarda a instituição e notifica', () async {
    final provider = InstitutionProvider(MockInstitutionService());
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.register(
      userId: 'u3',
      name: 'ONG',
      cnpj: '11222333000181',
      phone: '11999998888',
      address: 'Rua A',
      city: 'SP',
      storageCapacity: 500,
    );

    expect(provider.institution?.status, InstitutionStatus.pending);
    expect(notified, 1);
  });

  test('load troca de usuário limpa a instituição anterior', () async {
    final provider = InstitutionProvider(MockInstitutionService());
    await provider.register(
      userId: 'u3',
      name: 'ONG',
      cnpj: '11222333000181',
      phone: '11999998888',
      address: 'Rua A',
      city: 'SP',
      storageCapacity: 500,
    );
    await provider.load('u4');
    expect(provider.institution, isNull);
  });
}
