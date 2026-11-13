import '../../core/api_client.dart';
import '../../models/models.dart';
import '../api_exception.dart';
import '../institution_service.dart';

class HttpInstitutionService implements InstitutionService {
  final ApiClient _api;
  HttpInstitutionService(this._api);

  Institution _one(dynamic json) =>
      Institution.fromJson(json as Map<String, dynamic>);

  /// A API aceita ids numéricos; o app guarda ids como texto.
  List<int> _ids(List<String> ids) => ids.map(int.parse).toList();

  @override
  Future<Institution> registerInstitution({
    required String name,
    required String cnpj,
    required String address,
    required String city,
    required String areaOfActivity,
    required double storageCapacityKg,
    required List<String> categoryIds,
    double? latitude,
    double? longitude,
  }) async => _one(
    await _api.post(
      '/api/institutions',
      body: {
        'name': name,
        'cnpj': cnpj,
        'address': address,
        'city': city,
        'areaOfActivity': areaOfActivity,
        'storageCapacityKg': storageCapacityKg,
        'categoryIds': _ids(categoryIds),
        'latitude': latitude,
        'longitude': longitude,
      },
    ),
  );

  @override
  Future<Institution?> getMine() async {
    try {
      return _one(await _api.get('/api/institutions/me'));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<Institution> updateMine({
    required String name,
    required String address,
    required String city,
    required String areaOfActivity,
    required double storageCapacityKg,
    double? latitude,
    double? longitude,
  }) async => _one(
    await _api.put(
      '/api/institutions/me',
      body: {
        'name': name,
        'address': address,
        'city': city,
        'areaOfActivity': areaOfActivity,
        'storageCapacityKg': storageCapacityKg,
        'latitude': latitude,
        'longitude': longitude,
      },
    ),
  );

  @override
  Future<Institution> updateCategories(List<String> categoryIds) async => _one(
    await _api.put(
      '/api/institutions/me/categories',
      body: {'categoryIds': _ids(categoryIds)},
    ),
  );

  @override
  Future<List<Institution>> listByStatus(InstitutionStatus status) async {
    final json = await _api.get(
      '/api/institutions',
      query: {'status': status.apiValue},
    );
    return (json as List).map(_one).toList();
  }

  @override
  Future<Institution> approve(String id) async =>
      _one(await _api.put('/api/institutions/$id/approve'));

  @override
  Future<Institution> reject(String id, String reason) async => _one(
    await _api.put('/api/institutions/$id/reject', body: {'reason': reason}),
  );
}
