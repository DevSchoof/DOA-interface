import '../models/models.dart';

/// Erro de negócio de autenticação, com mensagem pronta para exibir na tela.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

abstract class AuthService {
  /// PB-001: login com e-mail e senha.
  Future<AuthSession> login(String email, String password);

  /// PB-002: encerra a sessão e invalida o token.
  Future<void> logout(String token);

  /// PB-003: cadastro de usuário com perfil (somente administrador).
  Future<User> registerUser({
    required String email,
    required String password,
    required UserRole role,
  });
}
