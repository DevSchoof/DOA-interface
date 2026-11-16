import '../../core/api_client.dart';
import '../../models/models.dart';
import '../auth_service.dart';

class HttpAuthService implements AuthService {
  final ApiClient _api;
  HttpAuthService(this._api);

  /// O AuthProvider mostra a mensagem de [AuthException]; por isso todo erro
  /// (credencial, conta bloqueada ou falha de rede) sai como AuthException.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<AuthSession> login(String email, String password) => _guard(() async {
    final json = await _api.postPublic(
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return AuthSession.fromJson(json as Map<String, dynamic>);
  });

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) => _guard(() async {
    final json = await _api.postPublic(
      '/api/auth/register',
      body: {'email': email.trim(), 'password': password, 'role': role.apiValue},
    );
    return AuthSession.fromJson(json as Map<String, dynamic>);
  });

  @override
  Future<void> logout(String token) async {
    await _api.postPublic('/api/auth/logout');
  }

  @override
  Future<User> registerUser({
    required String email,
    required String password,
    required UserRole role,
  }) => _guard(() async {
    final json = await _api.post(
      '/api/users',
      body: {'email': email.trim(), 'password': password, 'role': role.apiValue},
    );
    return User.fromJson(json as Map<String, dynamic>);
  });
}
