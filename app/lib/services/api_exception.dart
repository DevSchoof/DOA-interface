/// Erro com mensagem pronta para exibir ao usuário.
/// [statusCode] é o código HTTP quando o erro veio da API (nulo em falha de rede).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
