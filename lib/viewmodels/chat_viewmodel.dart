
// // lib/viewmodels/chat_viewmodel.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/foundation.dart';
// import 'package:uuid/uuid.dart';
// import '../models/message.dart';
// import '../services/gemini_service.dart';

// class ChatViewModel extends ChangeNotifier {
//   final GeminiService _service;
//   final List<Message> _messages = [];
//   bool _isLoading = false;

//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   ChatViewModel({GeminiService? service})
//       : _service = service ?? GeminiService();

//   List<Message> get messages => List.unmodifiable(_messages);
//   bool get isLoading => _isLoading;

//   /// Send message and save conversation (chatId optional)
//   Future<void> sendUserMessage(String text, {String? chatId}) async {
//     final id = Uuid().v4();
//     final userMsg = Message(
//       id: id,
//       text: text,
//       sender: MessageSender.user,
//       createdAt: DateTime.now(),
//     );
//     _messages.add(userMsg);

//     _isLoading = true;
//     notifyListeners();

//     try {
//       final recentMessages = _messages.length > 4
//           ? _messages.sublist(_messages.length - 4)
//           : _messages;

//       final context = recentMessages.map((msg) {
//         return {
//           "role": msg.sender == MessageSender.user ? "user" : "model",
//           "parts": [
//             {"text": msg.text}
//           ]
//         };
//       }).toList();

//       final reply = await _service.sendMessage(text, context);

//       final botMsg = Message(
//         id: Uuid().v4(),
//         text: reply,
//         sender: MessageSender.bot,
//         createdAt: DateTime.now(),
//       );
//       _messages.add(botMsg);

//       // Save both messages to Firestore (createdAt stored as Firestore Timestamp)
//       final cid = chatId ?? DateTime.now().millisecondsSinceEpoch.toString();
//       await _saveMessageToFirestore(cid, userMsg);
//       await _saveMessageToFirestore(cid, botMsg);
//     } catch (e) {
//       _messages.add(
//         Message(
//           id: Uuid().v4(),
//           text: 'Error: $e',
//           sender: MessageSender.bot,
//           createdAt: DateTime.now(),
//         ),
//       );
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Save single message to Firestore under chats/{chatId}/messages/{messageId}
//   Future<void> _saveMessageToFirestore(String chatId, Message msg) async {
//     await _db
//         .collection("chats")
//         .doc(chatId)
//         .collection("messages")
//         .doc(msg.id)
//         .set({
//       "id": msg.id,
//       "text": msg.text,
//       // store as 'user' or 'bot' for easy reading
//       "sender": msg.sender == MessageSender.user ? 'user' : 'bot',
//       // store createdAt as a Firestore Timestamp (sortable)
//       "createdAt": Timestamp.fromDate(msg.createdAt),
//     });
//   }

//   /// Fetch list of chat document ids (previous chats)
//   Future<List<String>> fetchChatIds() async {
//     final snapshot = await _db.collection("chats").get();
//     return snapshot.docs.map((doc) => doc.id).toList();
//   }

//   /// Load chat messages from Firestore into _messages (ordered by createdAt)
//   Future<void> loadChat(String chatId) async {
//     _messages.clear();
//     final snapshot = await _db
//         .collection("chats")
//         .doc(chatId)
//         .collection("messages")
//         .orderBy("createdAt")
//         .get();

//     for (var doc in snapshot.docs) {
//       final data = doc.data();

//       // createdAt might be stored as Timestamp or String; handle both
//       DateTime createdAt;
//       final createdAtField = data['createdAt'];
//       if (createdAtField is Timestamp) {
//         createdAt = createdAtField.toDate();
//       } else if (createdAtField is String) {
//         createdAt = DateTime.parse(createdAtField);
//       } else {
//         // fallback
//         createdAt = DateTime.now();
//       }

//       final senderString = (data['sender'] ?? 'bot') as String;
//       final sender =
//           senderString == 'user' ? MessageSender.user : MessageSender.bot;

//       _messages.add(Message(
//         id: data['id'] as String,
//         text: data['text'] as String,
//         sender: sender,
//         createdAt: createdAt,
//       ));
//     }
//     notifyListeners();
//   }

//   /// Clear in-memory messages (does NOT delete Firestore data)
//   void clear() {
//     _messages.clear();
//     notifyListeners();
//   }
// }




// lib/viewmodels/chat_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';

class ChatSummary {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime updatedAt;

  ChatSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory ChatSummary.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final updatedField = data['updatedAt'];
    DateTime updatedAt;
    if (updatedField is Timestamp) {
      updatedAt = updatedField.toDate();
    } else if (updatedField is String) {
      updatedAt = DateTime.tryParse(updatedField) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }
    return ChatSummary(
      id: doc.id,
      title: data['title'] as String? ?? 'Chat',
      lastMessage: data['lastMessage'] as String? ?? '',
      updatedAt: updatedAt,
    );
  }
}

class ChatViewModel extends ChangeNotifier {
  final GeminiService _service;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _currentChatId;

  ChatViewModel({GeminiService? service}) : _service = service ?? GeminiService();

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get currentChatId => _currentChatId;

  /// Stream of chat summaries (ordered by updatedAt desc)
  Stream<List<ChatSummary>> chatSummariesStream() {
    return _db
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatSummary.fromDoc(d)).toList());
  }

  /// Create a new chat document and make it current
  Future<String> createNewChat({String? title}) async {
    final chatId = const Uuid().v4();
    final now = Timestamp.now();
    await _db.collection('chats').doc(chatId).set({
      'title': title ?? 'Chat ${DateTime.now().toLocal()}',
      'lastMessage': '',
      'createdAt': now,
      'updatedAt': now,
    });
    _currentChatId = chatId;
    _messages.clear();
    notifyListeners();
    return chatId;
  }

  /// Load chat messages into memory
  Future<void> loadChat(String chatId) async {
    _currentChatId = chatId;
    _messages.clear();
    notifyListeners();

    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      _messages.add(Message.fromJson(data));
    }
    notifyListeners();
  }

  /// Save message + update chat metadata
  Future<void> _saveMessage(String chatId, Message msg) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(msg.id)
        .set({
      'id': msg.id,
      'text': msg.text,
      'sender': msg.sender == MessageSender.user ? 'user' : 'bot',
      'createdAt': Timestamp.fromDate(msg.createdAt),
    });

    await _db.collection('chats').doc(chatId).set({
      'lastMessage': msg.text,
      'updatedAt': Timestamp.fromDate(msg.createdAt),
    }, SetOptions(merge: true));
  }

  /// Send user message, ask Gemini, save both messages (creates chat if needed)
  Future<void> sendUserMessage(String text) async {
    // Ensure chat exists
    if (_currentChatId == null) {
      await createNewChat();
    }
    final chatId = _currentChatId!;

    final userMsg = Message(
      id: const Uuid().v4(),
      text: text,
      sender: MessageSender.user,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    // Save user message immediately
    await _saveMessage(chatId, userMsg);

    _isLoading = true;
    notifyListeners();

    try {
      // last 4 messages as context
      final recentMessages = _messages.length > 4
          ? _messages.sublist(_messages.length - 4)
          : _messages;

      final context = recentMessages.map((msg) {
        return {
          'role': msg.sender == MessageSender.user ? 'user' : 'model',
          'parts': [
            {'text': msg.text}
          ],
        };
      }).toList();

      final reply = await _service.sendMessage(text, context);

      final botMsg = Message(
        id: const Uuid().v4(),
        text: reply,
        sender: MessageSender.bot,
        createdAt: DateTime.now(),
      );
      _messages.add(botMsg);
      await _saveMessage(chatId, botMsg);
    } catch (e) {
      final errMsg = Message(
        id: const Uuid().v4(),
        text: 'Error: $e',
        sender: MessageSender.bot,
        createdAt: DateTime.now(),
      );
      _messages.add(errMsg);
      await _saveMessage(chatId, errMsg);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete chat and its messages (optional)
  Future<void> deleteChat(String chatId) async {
    final messagesSnap = await _db.collection('chats').doc(chatId).collection('messages').get();
    for (var doc in messagesSnap.docs) {
      await doc.reference.delete();
    }
    await _db.collection('chats').doc(chatId).delete();

    if (_currentChatId == chatId) {
      _currentChatId = null;
      _messages.clear();
      notifyListeners();
    }
  }

  /// Clear only in-memory messages (does not delete firestore)
  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
