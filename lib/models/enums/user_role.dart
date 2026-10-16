enum UserRole {
  donor,
  institution,
  admin,
  unknown;

  /// Converte o texto da API (ex.: "DONOR") em [UserRole].
  /// Valor nulo ou desconhecido retorna [UserRole.unknown].
  static UserRole fromString(String? value) => UserRole.values.firstWhere(
    (e) => e.name == value?.toLowerCase(),
    orElse: () => UserRole.unknown,
  );

  /// Valor enviado à API (ex.: "DONOR").
  String get apiValue => name.toUpperCase();
}
