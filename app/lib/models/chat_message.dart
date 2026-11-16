class ChatMessage {
  final String id;
  final String donationId;
  final String senderUserId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.donationId,
    required this.senderUserId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  /// Serve para a resposta da API e para o evento `chat` do WebSocket.
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'].toString(),
    donationId: json['donationId'].toString(),
    senderUserId: json['senderUserId'].toString(),
    senderName: json['senderName'] as String,
    content: json['content'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
  );
}
