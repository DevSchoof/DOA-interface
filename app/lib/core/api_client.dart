import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/api_exception.dart';

/// Camada de rede: concentra URL, token, JSON, timeout e tradução de erros.
/// Os serviços HTTP usam só esta classe e nunca o pacote `http` direto.
class ApiClient {
  final String baseUrl;
  final String? Function() tokenProvider;

  /// Chamado quando a API responde 401 numa rota protegida (sessão expirada).
  void Function()? onUnauthorized;

  final http.Client _http;
  static const _timeout = Duration(seconds: 20);

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    this.onUnauthorized,
    http.Client? client,
  }) : _http = client ?? http.Client();

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
  }) => _send('POST', path, body: body ?? const {}, auth: auth);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body ?? const {});

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Envia um arquivo (multipart/form-data) no campo [field]. Usado no upload de fotos.
  Future<dynamic> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    final token = tokenProvider();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    try {
      // fotos demoram mais que o JSON: prazo maior
      final streamed = await _http.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      return _handle(response, notifyUnauthorized: true);
    } on TimeoutException {
      throw const ApiException('O envio da foto demorou demais. Tente novamente.');
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Confira a conexão e o endereço da API.',
      );
    }
  }

  /// Para login, cadastro e logout: um 401 aqui é erro de credencial, não sessão expirada.
  Future<dynamic> postPublic(String path, {Object? body}) =>
      _send('POST', path, body: body ?? const {}, auth: false);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool auth = true,
  }) async {
    final params = <String, String>{
      for (final e in (query ?? const <String, Object?>{}).entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: params.isEmpty ? null : params);

    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final token = tokenProvider();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    try {
      final streamed = await _http.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handle(response, notifyUnauthorized: auth);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Tente novamente em instantes.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Confira a conexão e o endereço da API.',
      );
    }
  }

  dynamic _handle(http.Response response, {required bool notifyUnauthorized}) {
    // utf8.decode(bodyBytes): o `body` do pacote http assume latin1 quando o
    // Content-Type não declara charset, o que estragaria os acentos.
    final text = utf8.decode(response.bodyBytes);
    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      return text.isEmpty ? null : jsonDecode(text);
    }

    if (code == 401 && notifyUnauthorized) onUnauthorized?.call();
    throw ApiException(_messageFrom(text, code), statusCode: code);
  }

  static String _messageFrom(String text, int code) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // corpo vazio ou não JSON
    }
    return switch (code) {
      401 => 'Sessão inválida ou expirada. Entre novamente.',
      403 => 'Você não tem permissão para esta ação.',
      404 => 'Não encontrado.',
      >= 500 => 'Erro no servidor. Tente novamente mais tarde.',
      _ => 'Não foi possível concluir a operação.',
    };
  }
}
