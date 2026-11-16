import '../models/models.dart';

abstract class StockService {
  /// Instituição: itens em estoque, do que vence primeiro ao que vence depois.
  Future<List<StockItem>> listStock();
}
