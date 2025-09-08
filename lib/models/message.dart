enum MessageSender { user, bot }

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime createdAt;

  Message({required this.id, required this.text, required this.sender, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender == MessageSender.user ? 'user' : 'bot',
        'createdAt': createdAt.toIso8601String(),
      };
}
