enum PersonType {
  individual, // pessoa física
  company, // pessoa jurídica
  unknown;

  static PersonType fromString(String? value) => PersonType.values.firstWhere(
    (e) => e.name == value?.toLowerCase(),
    orElse: () => PersonType.unknown,
  );

  /// Valor enviado à API (ex.: "INDIVIDUAL").
  String get apiValue => name.toUpperCase();
}
