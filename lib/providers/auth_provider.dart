import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/session_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SessionStorage _storage;

  AuthProvider(this._authService, this._storage);

  AuthSession? _session;
  bool _isLoading = false;
  String? _error;

  AuthSession? get session => _session;
  User? get user => _session?.user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Perfil desconhecido nunca conta como autenticado.
  bool get isAuthenticated =>
      _session != null && _session!.user.role != UserRole.unknown;

  /// Recupera a sessão guardada no aparelho (chamado ao abrir o app).
  Future<void> restoreSession() async {
    _session = await _storage.read();
    notifyListeners();
  }

  /// PB-001: retorna true se o login deu certo.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _authService.login(email, password);
      await _storage.save(session);
      _session = session;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Não foi possível entrar. Tente novamente.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// PB-002: encerra a sessão. Limpa o estado local mesmo se a API falhar.
  Future<void> logout() async {
    final token = _session?.token;
    try {
      if (token != null) await _authService.logout(token);
    } catch (_) {
      // ignora: o logout local deve sempre acontecer
    }
    await _storage.clear();
    _session = null;
    notifyListeners();
  }
}
