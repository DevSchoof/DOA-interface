import '../core/config.dart';
import 'enums/donation_status.dart';

class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String categoryId;
  final String categoryName;
  final String description;
  final double quantity;
  final String unit; // kg, un, L
  final DateTime expiresAt; // só a data importa
  final String? storageConditions;
  final DonationStatus status;
  final String? reservedById; // id da instituição que reservou
  final String? reservedByName;
  final DateTime? reservedAt;
  final DateTime createdAt;
  final String city;

  /// Calculada pela API a partir da localização da instituição logada.
  final double? distanceKm;

  /// URLs completas das fotos (a API envia caminhos relativos). A primeira é a capa.
  final List<String> photoUrls;

  const Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.expiresAt,
    this.storageConditions,
    required this.status,
    this.reservedById,
    this.reservedByName,
    this.reservedAt,
    required this.createdAt,
    required this.city,
    this.distanceKm,
    this.photoUrls = const [],
  });

  /// Dias até a validade (0 = vence hoje, negativo = vencida).
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final expiry = DateTime.utc(expiresAt.year, expiresAt.month, expiresAt.day);
    return expiry.difference(today).inDays;
  }

  /// Regra de negócio: validade de até 3 dias é prioritária.
  bool get isPriority =>
      status == DonationStatus.available && daysUntilExpiry <= 3;

  Donation copyWith({
    DonationStatus? status,
    String? reservedById,
    String? reservedByName,
    DateTime? reservedAt,
  }) => Donation(
    id: id,
    donorId: donorId,
    donorName: donorName,
    categoryId: categoryId,
    categoryName: categoryName,
    description: description,
    quantity: quantity,
    unit: unit,
    expiresAt: expiresAt,
    storageConditions: storageConditions,
    status: status ?? this.status,
    reservedById: reservedById ?? this.reservedById,
    reservedByName: reservedByName ?? this.reservedByName,
    reservedAt: reservedAt ?? this.reservedAt,
    createdAt: createdAt,
    city: city,
    distanceKm: distanceKm,
    photoUrls: photoUrls,
  );

  factory Donation.fromJson(Map<String, dynamic> json) => Donation(
    id: json['id'].toString(),
    donorId: json['donorId'].toString(),
    donorName: json['donorName'] as String,
    categoryId: json['categoryId'].toString(),
    categoryName: json['categoryName'] as String,
    description: json['description'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    storageConditions: json['storageConditions'] as String?,
    status: DonationStatus.fromString(json['status'] as String?),
    reservedById: json['reservedById']?.toString(),
    reservedByName: json['reservedByName'] as String?,
    reservedAt: json['reservedAt'] == null
        ? null
        : DateTime.parse(json['reservedAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    city: json['city'] as String,
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    photoUrls: [
      for (final u in (json['photoUrls'] as List? ?? const []))
        u.toString().startsWith('http') ? u.toString() : '${ApiConfig.baseUrl}$u',
    ],
  );
}
