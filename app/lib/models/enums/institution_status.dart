enum InstitutionStatus {
  pending('Em análise'),
  approved('Aprovada'),
  rejected('Rejeitada'),
  unknown('Desconhecido');

  final String label;
  const InstitutionStatus(this.label);

  static InstitutionStatus fromString(String? value) =>
      InstitutionStatus.values.firstWhere(
        (e) => e.name == value?.toLowerCase(),
        orElse: () => InstitutionStatus.unknown,
      );

  String get apiValue => name.toUpperCase();
}
