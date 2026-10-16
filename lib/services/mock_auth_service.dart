import '../models/models.dart';
import 'auth_service.dart';

class _Account {
  final User user;
  final String password;
  const _Account(this.user, this.password);
}

class MockAuthService implements AuthService {
  final List<_Account> _accounts = [
    _Account(
      User(
        id: 'u1',
        email: 'admin@doa.com',
        role: UserRole.admin,
        createdAt: DateTime(2026, 9, 1),
      ),
      'admin123',
    ),
    _Account(
      User(
        id: 'u2',
        email: 'doador@doa.com',
        role: UserRole.donor,
        createdAt: DateTime(2026, 9, 1),
      ),
      'doador123',
    ),
    _Account(
      User(
        id: 'u3',
        email: 'ong@doa.com',
        role: UserRole.institution,
        createdAt: DateTime(2026, 9, 1),
      ),
      'ong123',
    ),
  ];

  final Set<String> _validTokens = {};

  Future<void> _latency() => Future.delayed(const Duration(milliseconds: 500));

  @override
  Future<AuthSession> login(String email, String password) async {
    await _latency();

    final normalized = email.trim().toLowerCase();
    final matches = _accounts.where(
      (a) => a.user.email == normalized && a.password == password,
    );

    if (matches.isEmpty) {
      throw const AuthException('E-mail ou senha inválidos.');
    }

    final user = matches.first.user;
    if (!user.isActive) {
      throw const AuthException('Conta suspensa. Contate o administrador.');
    }

    final token =
        'mock-token-${user.id}-${DateTime.now().millisecondsSinceEpoch}';
    _validTokens.add(token);
    return AuthSession(token: token, user: user);
  }

  @override
  Future<void> logout(String token) async {
    await _latency();
    _validTokens.remove(token);
  }

  @override
  Future<User> registerUser({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await _latency();

    final normalized = email.trim().toLowerCase();

    if (role == UserRole.unknown) {
      throw const AuthException('Selecione um perfil válido.');
    }
    if (password.length < 6) {
      throw const AuthException('A senha deve ter ao menos 6 caracteres.');
    }
    if (_accounts.any((a) => a.user.email == normalized)) {
      throw const AuthException('Já existe um usuário com este e-mail.');
    }

    final user = User(
      id: 'u${_accounts.length + 1}',
      email: normalized,
      role: role,
      createdAt: DateTime.now(),
    );
    _accounts.add(_Account(user, password));
    return user;
  }
}
