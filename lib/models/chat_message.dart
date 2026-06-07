class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final List<String> quickReplies;
  final String? actionType;
  final String? actionData;

  ChatMessage({
    required this.text,
    required this.isBot,
    DateTime? timestamp,
    this.quickReplies = const [],
    this.actionType,
    this.actionData,
  }) : timestamp = timestamp ?? DateTime.now();
}
