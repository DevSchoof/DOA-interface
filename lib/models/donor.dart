import 'enums/person_type.dart';

class Donor {
  final String id;
  final String userId;
  final PersonType personType;
  final String name; // nome ou razão social
  final String? document; // CPF ou CNPJ, só dígitos
  final String phone;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;

  const Donor({
    required this.id,
    required this.userId,
    required this.personType,
    required this.name,
    this.document,
    required this.phone,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
  });

  factory Donor.fromJson(Map<String, dynamic> json) => Donor(
    id: json['id'].toString(),
    userId: json['userId'].toString(),
    personType: PersonType.fromString(json['personType'] as String?),
    name: json['name'] as String,
    document: json['document'] as String?,
    phone: json['phone'] as String,
    address: json['address'] as String,
    city: json['city'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'personType': personType.apiValue,
    'name': name,
    'document': document,
    'phone': phone,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
  };
}
