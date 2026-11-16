import '../models/models.dart';

abstract class CategoryService {
  /// Categorias ativas (o administrador pode pedir também as inativas).
  Future<List<FoodCategory>> list({bool includeInactive = false});

  // Somente administrador
  Future<FoodCategory> create({required String name, String? description});

  Future<FoodCategory> update(
    String id, {
    required String name,
    String? description,
    required bool active,
  });

  Future<void> delete(String id);
}
