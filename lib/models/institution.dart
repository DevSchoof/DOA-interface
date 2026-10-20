import 'enums/institution_status.dart';

class Institution {
  final String id;
  final String userId;
  final String name;
  final String cnpj; // só dígitos
  final String phone;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final double storageCapacity; // capacidade volumétrica
  final InstitutionStatus status;

  const Institution({
    required this.id,
    required this.userId,
    required this.name,
    required this.cnpj,
    required this.phone,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    required this.storageCapacity,
    this.status = InstitutionStatus.pending,
  });

  bool get isApproved => status == InstitutionStatus.approved;

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: json['id'].toString(),
    userId: json['userId'].toString(),
    name: json['name'] as String,
    cnpj: json['cnpj'] as String,
    phone: json['phone'] as String,
    address: json['address'] as String,
    city: json['city'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    storageCapacity: (json['storageCapacity'] as num).toDouble(),
    status: InstitutionStatus.fromString(json['status'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'cnpj': cnpj,
    'phone': phone,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'storageCapacity': storageCapacity,
    'status': status.apiValue,
  };
}
