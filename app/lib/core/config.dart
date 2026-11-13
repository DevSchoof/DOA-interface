import 'package:flutter/foundation.dart';

/// Endereço da API.
///
/// Padrões (sem configurar nada):
/// - Chrome/web e desktop: http://localhost:8080
/// - Emulador Android: http://10.0.2.2:8080 (é como o emulador enxerga o seu computador)
///
/// Para trocar (celular físico, servidor publicado):
///   flutter run --dart-define=API_URL=http://192.168.0.10:8080
///   flutter run --dart-define=API_URL=https://doa-api.onrender.com
class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv.replaceAll(RegExp(r'/+$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// URL do WebSocket (ws:// ou wss:// conforme o HTTP/HTTPS da API).
  static String get websocketUrl =>
      '${baseUrl.replaceFirst(RegExp(r'^http'), 'ws')}/ws';
}
