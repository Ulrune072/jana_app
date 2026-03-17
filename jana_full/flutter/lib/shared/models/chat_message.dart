class ChatMessage {
  final String role;    // 'user' or 'assistant'
  final String content;
  final String sentAt;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      role:    j['role'] as String,
      content: j['content'] as String,
      sentAt:  j['sent_at'] as String,
    );
  }

  bool get isUser => role == 'user';
}
