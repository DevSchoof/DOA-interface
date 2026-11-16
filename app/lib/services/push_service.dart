import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';

/// Push notifications (Firebase Cloud Messaging), só no Android.
/// No Chrome/desktop não faz nada: as notificações em tempo real vêm pelo WebSocket.
///
/// Fluxo: o app pede permissão, obtém o token do aparelho e o registra na API
/// (PUT /api/users/me/fcm-token). A API envia o push para esse token quando há
/// nova doação compatível ou mudança de status da reserva.
class PushService {
  final ApiClient _api;
  PushService(this._api);

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool _initialized = false;
  StreamSubscription<String>? _refreshSub;

  /// Id da doação de uma notificação tocada (app aberto pela notificação).
  final _taps = StreamController<String>.broadcast();
  Stream<String> get donationTaps => _taps.stream;

  /// Inicializa o Firebase (uma vez). Chame no início do app.
  Future<void> init() async {
    if (!supported || _initialized) return;
    try {
      await Firebase.initializeApp(); // usa o google-services.json do Android
      _initialized = true;

      // app em segundo plano: o usuário tocou na notificação
      FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
      // app fechado: foi aberto pela notificação
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _onTap(initial);
    } catch (e) {
      debugPrint('Push desativado: $e');
    }
  }

  void _onTap(RemoteMessage message) {
    final id = message.data['donationId'];
    if (id != null && id.toString().isNotEmpty) _taps.add(id.toString());
  }

  /// Pede permissão, pega o token e registra na API. Chame depois do login.
  Future<void> registerForCurrentUser() async {
    if (!_initialized) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) await _send(token);

      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen(_send);
    } catch (e) {
      debugPrint('Não foi possível registrar o push: $e');
    }
  }

  /// Chame no logout: para de ouvir e apaga o token do aparelho (não recebe push de outra conta).
  Future<void> unregister() async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (!_initialized) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> _send(String token) async {
    try {
      await _api.put('/api/users/me/fcm-token', body: {'token': token});
    } catch (e) {
      debugPrint('Falha ao enviar o token do push à API: $e');
    }
  }
}
