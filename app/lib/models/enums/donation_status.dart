enum DonationStatus {
  available('Disponível'),
  reserved('Reservada'),
  delivered('Entregue'),
  cancelled('Cancelada'),
  expired('Expirada'),
  unknown('Desconhecido');

  final String label;
  const DonationStatus(this.label);

  static DonationStatus fromString(String? value) =>
      DonationStatus.values.firstWhere(
        (e) => e.name == value?.toLowerCase(),
        orElse: () => DonationStatus.unknown,
      );

  String get apiValue => name.toUpperCase();
}
