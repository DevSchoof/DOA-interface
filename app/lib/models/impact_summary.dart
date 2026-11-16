class ImpactSummary {
  final int donationsCount;
  final int deliveredCount;
  final double wasteAvoidedKg;
  final int peopleServed;
  final int institutionsServed;

  const ImpactSummary({
    required this.donationsCount,
    required this.deliveredCount,
    required this.wasteAvoidedKg,
    required this.peopleServed,
    required this.institutionsServed,
  });

  factory ImpactSummary.fromJson(Map<String, dynamic> json) => ImpactSummary(
    donationsCount: (json['donationsCount'] as num).toInt(),
    deliveredCount: (json['deliveredCount'] as num).toInt(),
    wasteAvoidedKg: (json['wasteAvoidedKg'] as num).toDouble(),
    peopleServed: (json['peopleServed'] as num).toInt(),
    institutionsServed: (json['institutionsServed'] as num).toInt(),
  );
}
