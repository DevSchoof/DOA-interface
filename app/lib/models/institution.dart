import 'enums/institution_status.dart';
import 'food_category.dart';

class Institution {
  final String id;
  final String userId;
  final String name;
  final String cnpj; // só dígitos
  final String address;
  final String city;
  final String areaOfActivity;
  final double storageCapacityKg;
  final InstitutionStatus status;
  final String? rejectionReason;
  final double? latitude;
  final double? longitude;

  /// N:N: categorias de alimento que a instituição aceita receber.
  final List<FoodCategory> categories;

  const Institution({
    required this.id,
    required this.userId,
    required this.name,
    required this.cnpj,
    required this.address,
    required this.city,
    required this.areaOfActivity,
    required this.storageCapacityKg,
    required this.status,
    this.rejectionReason,
    this.latitude,
    this.longitude,
    this.categories = const [],
  });

  Institution copyWith({InstitutionStatus? status, String? rejectionReason}) =>
      Institution(
        id: id,
        userId: userId,
        name: name,
        cnpj: cnpj,
        address: address,
        city: city,
        areaOfActivity: areaOfActivity,
        storageCapacityKg: storageCapacityKg,
        status: status ?? this.status,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        latitude: latitude,
        longitude: longitude,
        categories: categories,
      );

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'].toString(),
    userId: json['userId'].toString(),
    name: json['name'] as String,
    cnpj: json['cnpj'] as String,
    address: json['address'] as String,
    city: json['city'] as String,
    areaOfActivity: json['areaOfActivity'] as String,
    storageCapacityKg: (json['storageCapacityKg'] as num).toDouble(),
    status: InstitutionStatus.fromString(json['status'] as String?),
    rejectionReason: json['rejectionReason'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    categories: ((json['categories'] as List?) ?? const [])
        .map((c) => FoodCategory.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
