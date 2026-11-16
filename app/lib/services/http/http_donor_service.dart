import '../../core/api_client.dart';
import '../../models/models.dart';
import '../api_exception.dart';
import '../donor_service.dart';

class HttpDonorService implements DonorService {
  final ApiClient _api;
  HttpDonorService(this._api);

  @override
  Future<Donor> registerDonor({
    required String userId, // ignorado: a API usa o usuário do token
    required PersonType personType,
    required String name,
    required String document,
    required String phone,
    required String address,
    required String city,
    double? latitude,
    double? longitude,
  }) async {
    final json = await _api.post(
      '/api/donors',
      body: {
        'personType': personType.apiValue,
        'name': name,
        'document': document,
        'phone': phone,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return Donor.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Donor?> getMine() async {
    try {
      final json = await _api.get('/api/donors/me');
      return Donor.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isNotFound) return null; // ainda não completou o cadastro
      rethrow;
    }
  }

  @override
  Future<Donor> updateMine({
    required String name,
    required String phone,
    required String address,
    required String city,
    double? latitude,
    double? longitude,
  }) async {
    final json = await _api.put(
      '/api/donors/me',
      body: {
        'name': name,
        'phone': phone,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return Donor.fromJson(json as Map<String, dynamic>);
  }
}
