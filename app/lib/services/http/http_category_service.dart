import '../../core/api_client.dart';
import '../../models/models.dart';
import '../category_service.dart';

class HttpCategoryService implements CategoryService {
  final ApiClient _api;
  HttpCategoryService(this._api);

  @override
  Future<List<FoodCategory>> list({bool includeInactive = false}) async {
    final json = await _api.get(
      '/api/categories',
      query: {'includeInactive': includeInactive ? 'true' : null},
    );
    return (json as List)
        .map((c) => FoodCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FoodCategory> create({required String name, String? description}) async {
    final json = await _api.post(
      '/api/categories',
      body: {'name': name, 'description': description},
    );
    return FoodCategory.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<FoodCategory> update(
    String id, {
    required String name,
    String? description,
    required bool active,
  }) async {
    final json = await _api.put(
      '/api/categories/$id',
      body: {'name': name, 'description': description, 'active': active},
    );
    return FoodCategory.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _api.delete('/api/categories/$id');
  }
}
