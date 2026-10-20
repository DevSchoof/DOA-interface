import 'package:doa_interface/models/models.dart';
import 'package:doa_interface/services/auth_service.dart';
import 'package:doa_interface/services/mock_donor_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockDonorService service;

  setUp(() => service = MockDonorService());

  Future<Donor> register({
    String document = '52998224725',
    PersonType type = PersonType.individual,
  }) => service.registerDonor(
    userId: 'u2',
    personType: type,
    name: 'Maria Silva',
    document: document,
    phone: '11999998888',
    address: 'Rua das Flores, 100',
    city: 'São Paulo',
  );

  test('cadastra doador vinculado ao usuário', () async {
    final donor = await register();
    expect(donor.userId, 'u2');
    expect(donor.personType, PersonType.individual);
    expect(donor.document, '52998224725');
  });

  test('rejeita documento repetido', () async {
    await register();
    expect(register(), throwsA(isA<AuthException>()));
  });

  test('rejeita tipo de pessoa desconhecido', () {
    expect(register(type: PersonType.unknown), throwsA(isA<AuthException>()));
  });
}
