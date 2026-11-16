import 'package:flutter/foundation.dart';

import '../services/push_service.dart';

/// Liga o push à sessão: registra o token quando o usuário entra e o remove quando sai.
class PushProvider extends ChangeNotifier {
  final PushService service;
  PushProvider(this.service);

  String? _token;

  void sync(String? sessionToken) {
    if (sessionToken == _token) return;
    final wasLoggedIn = _token != null;
    _token = sessionToken;
    // adia: sync roda durante o build
    Future.microtask(() {
      if (sessionToken != null) {
        service.registerForCurrentUser();
      } else if (wasLoggedIn) {
        service.unregister();
      }
    });
  }
}
