import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

class SessionStorage {
  static const _key = 'auth_session';
  final FlutterSecureStorage _storage;

  const SessionStorage([this._storage = const FlutterSecureStorage()]);

  Future<void> save(AuthSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<AuthSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await clear(); // dado corrompido: descarta
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
