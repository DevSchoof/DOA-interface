import '../models/models.dart';
import 'api_exception.dart';

export 'api_exception.dart';

/// Erro de negócio de autenticação, com mensagem pronta para exibir na tela.
class AuthException extends ApiException {
  const AuthException(super.message);
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

  /// Cadastro público (RF01/RF02): só DONOR ou INSTITUTION. Já devolve a sessão.
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required UserRole role,
  });
}
