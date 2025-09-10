
// enum MessageSender { user, bot }

// class Message {
//   final String id;
//   final String text;
//   final MessageSender sender;
//   final DateTime createdAt;

//   /// Constructor
//   Message({
//     required this.id,
//     required this.text,
//     required this.sender,
//     DateTime? createdAt,
//   }) : createdAt = createdAt ?? DateTime.now();

//   /// Convert object → JSON (for Firebase)
//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'text': text,
//         'sender': sender == MessageSender.user ? 'user' : 'bot',
//         'createdAt': createdAt.toIso8601String(),
//       };

//   /// Convert JSON → object (when reading from Firebase)
//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id'] as String,
//       text: json['text'] as String,
//       sender: json['sender'] == 'user'
//           ? MessageSender.user
//           : MessageSender.bot,
//       createdAt: DateTime.parse(json['createdAt'] as String),
//     );
//   }
// }


// lib/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageSender { user, bot }

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender == MessageSender.user ? 'user' : 'bot',
        // NOTE: toJson uses ISO string — when saving to Firestore we will prefer Timestamp.fromDate()
        'createdAt': createdAt.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    // createdAt may be a Firestore Timestamp or an ISO string
    DateTime createdAt;
    final createdAtField = json['createdAt'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is String) {
      createdAt = DateTime.tryParse(createdAtField) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final senderString = (json['sender'] ?? 'bot') as String;
    final sender = senderString == 'user' ? MessageSender.user : MessageSender.bot;

    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: sender,
      createdAt: createdAt,
    );
  }
}
