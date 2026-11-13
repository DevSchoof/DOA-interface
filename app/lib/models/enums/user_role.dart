enum UserRole {
  donor('Doador'),
  institution('Instituição'),
  admin('Administrador'),
  unknown('Desconhecido');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
    (e) => e.name == value?.toLowerCase(),
    orElse: () => UserRole.unknown,
  );

  String get apiValue => name.toUpperCase();
}
