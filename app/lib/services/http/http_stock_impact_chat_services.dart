import '../../core/api_client.dart';
import '../../models/models.dart';
import '../chat_service.dart';
import '../impact_service.dart';
import '../stock_service.dart';

class HttpStockService implements StockService {
  final ApiClient _api;
  HttpStockService(this._api);

  @override
  Future<List<StockItem>> listStock() async {
    final json = await _api.get('/api/stock');
    return (json as List)
        .map((s) => StockItem.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}

class HttpImpactService implements ImpactService {
  final ApiClient _api;
  HttpImpactService(this._api);

  @override
  Future<ImpactSummary> getSummary() async => ImpactSummary.fromJson(
    await _api.get('/api/impact') as Map<String, dynamic>,
  );
}

class HttpChatService implements ChatService {
  final ApiClient _api;
  HttpChatService(this._api);

  @override
  Future<List<ChatMessage>> history(String donationId) async {
    final json = await _api.get('/api/donations/$donationId/messages');
    return (json as List)
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessage> send(String donationId, String content) async =>
      ChatMessage.fromJson(
        await _api.post(
          '/api/donations/$donationId/messages',
          body: {'content': content},
        ) as Map<String, dynamic>,
      );
}
