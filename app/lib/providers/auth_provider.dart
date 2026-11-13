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
    try {
      _session = await _storage.read();
    } catch (e) {
      // armazenamento indisponível ou corrompido: começa deslogado
      debugPrint('Não foi possível ler a sessão guardada: $e');
      _session = null;
    }
    notifyListeners();
  }

  /// Limpa a mensagem de erro ao trocar de tela (sem notificar: é chamado
  /// no initState das telas de login e cadastro).
  void clearError() => _error = null;

  /// PB-001: retorna true se o login deu certo.
  Future<bool> login(String email, String password) => _authenticate(
    () => _authService.login(email, password),
    'Não foi possível entrar. Tente novamente.',
  );

  /// Cadastro público de doador ou instituição. Já deixa o usuário logado.
  Future<bool> signUp(String email, String password, UserRole role) =>
      _authenticate(
        () => _authService.signUp(email: email, password: password, role: role),
        'Não foi possível criar a conta. Tente novamente.',
      );

  Future<bool> _authenticate(
    Future<AuthSession> Function() action,
    String fallbackError,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await action();
      try {
        await _storage.save(session);
      } catch (e) {
        // sem armazenamento seguro, a sessão vale só até fechar o app
        debugPrint('Não foi possível guardar a sessão: $e');
      }
      _session = session;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('Falha inesperada na autenticação: $e\n$stack');
      // em debug, mostra o motivo real para facilitar o diagnóstico
      _error = kDebugMode ? '$fallbackError\n($e)' : fallbackError;
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
