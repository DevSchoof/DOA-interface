class StockItem {
  final String id;
  final String categoryName;
  final String description;
  final double quantity;
  final String unit;
  final DateTime receivedAt;
  final DateTime expiresAt;

  const StockItem({
    required this.id,
    required this.categoryName,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.receivedAt,
    required this.expiresAt,
  });

  /// Fração da validade já consumida (0 a 1).
  double get validityUsed {
    final total = expiresAt.difference(receivedAt).inHours;
    if (total <= 0) return 1;
    final used = DateTime.now().difference(receivedAt).inHours;
    return (used / total).clamp(0.0, 1.0).toDouble();
  }

  /// Regra de negócio (RF14): alerta ao atingir 80% da validade.
  bool get isNearExpiry => validityUsed >= 0.8;

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    id: json['id'].toString(),
    categoryName: json['categoryName'] as String,
    description: json['description'] as String,
    quantity: (json['quantity'] as num).toDouble(),
    unit: json['unit'] as String,
    receivedAt: DateTime.parse(json['receivedAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}
