/// Categoria de alimento (gerenciada pelo administrador na API).
class FoodCategory {
  final String id;
  final String name;
  final String? description;
  final bool active;

  const FoodCategory({
    required this.id,
    required this.name,
    this.description,
    this.active = true,
  });

  factory FoodCategory.fromJson(Map<String, dynamic> json) => FoodCategory(
    id: json['id'].toString(),
    name: json['name'] as String,
    description: json['description'] as String?,
    active: json['active'] as bool? ?? true,
  );
}
