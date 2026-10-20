enum InstitutionStatus {
  pending('Pendente'),
  approved('Homologada'),
  rejected('Rejeitada'),
  suspended('Suspensa'),
  unknown('Desconhecido');

  final String label;
  const InstitutionStatus(this.label);

  static InstitutionStatus fromString(String? value) =>
      InstitutionStatus.values.firstWhere(
        (e) => e.name == value?.toLowerCase(),
        orElse: () => InstitutionStatus.unknown,
      );

  /// Valor enviado à API (ex.: "PENDING").
  String get apiValue => name.toUpperCase();
}
