import '../models/models.dart';

abstract class ChatService {
  Future<List<ChatMessage>> history(String donationId);

  /// Envia pela API; a mensagem também chega ao outro lado pelo WebSocket.
  Future<ChatMessage> send(String donationId, String content);
}
