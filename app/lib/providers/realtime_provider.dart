import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Conexão WebSocket com a API: notificações e mensagens do chat em tempo real.
/// Abre sozinha quando o usuário entra, fecha quando sai e tenta reconectar
/// (com espera crescente) se a conexão cair.
class RealtimeProvider extends ChangeNotifier {
  final String _url;
  RealtimeProvider(this._url);

  String? _token;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _connected = false;

  final _events = StreamController<Map<String, dynamic>>.broadcast();

  /// Eventos do servidor: `{"type":"notification"|"chat"|..., ...}`.
  Stream<Map<String, dynamic>> get events => _events.stream;
  bool get isConnected => _connected;

  /// Chamado pelo ProxyProvider sempre que a sessão muda.
  void sync(String? token) {
    if (token == _token) return;
    _token = token;
    _close();
    if (token != null) {
      Future.microtask(_connect); // adia: sync roda durante o build
    }
  }

  void _connect() {
    final token = _token;
    if (token == null) return;

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse('$_url?token=${Uri.encodeQueryComponent(token)}'),
      );
      _channel = channel;
      _subscription = channel.stream.listen(
        _onData,
        onDone: () => _onClosed(channel),
        onError: (_) => _onClosed(channel),
      );
      channel.ready.then((_) {
        if (_channel != channel) return;
        _attempt = 0;
        _setConnected(true);
      }).catchError((_) {
        // a falha chega também por onError/onDone, que agendam a nova tentativa
      });
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _onData(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is Map<String, dynamic>) _events.add(decoded);
    } catch (_) {
      // mensagem fora do protocolo: ignora
    }
  }

  void _onClosed(WebSocketChannel channel) {
    if (_channel != channel) return; // conexão antiga, já descartada
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _setConnected(false);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_token == null) return;
    _retryTimer?.cancel();
    final seconds = (1 << _attempt.clamp(0, 5)).clamp(1, 30);
    _attempt++;
    _retryTimer = Timer(Duration(seconds: seconds), _connect);
  }

  void _close() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    channel?.sink.close();
    _attempt = 0;
    _setConnected(false);
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _close();
    _events.close();
    super.dispose();
  }
}
