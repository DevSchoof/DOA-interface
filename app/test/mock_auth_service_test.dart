import 'package:doa_interface/models/models.dart';
import 'package:doa_interface/services/auth_service.dart';
import 'package:doa_interface/services/mock_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAuthService service;

  setUp(() => service = MockAuthService());

  test('cadastra usuário novo e permite login', () async {
    final user = await service.registerUser(
      email: 'Novo@Doa.com',
      password: 'senha123',
      role: UserRole.institution,
    );

    expect(user.email, 'novo@doa.com');
    expect(user.role, UserRole.institution);

    final session = await service.login('novo@doa.com', 'senha123');
    expect(session.user.id, user.id);
  });

  test('rejeita e-mail repetido', () {
    expect(
      service.registerUser(
        email: 'admin@doa.com',
        password: 'senha123',
        role: UserRole.donor,
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('rejeita senha curta', () {
    expect(
      service.registerUser(
        email: 'a@doa.com',
        password: '123',
        role: UserRole.donor,
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('rejeita perfil desconhecido', () {
    expect(
      service.registerUser(
        email: 'b@doa.com',
        password: 'senha123',
        role: UserRole.unknown,
      ),
      throwsA(isA<AuthException>()),
    );
  });
}
