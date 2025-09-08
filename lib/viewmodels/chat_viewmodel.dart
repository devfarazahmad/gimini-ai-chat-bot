import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';

class ChatViewModel extends ChangeNotifier {
  final GeminiService _service;
  final List<Message> _messages = [];
  bool _isLoading = false;

  ChatViewModel({GeminiService? service})
      : _service = service ?? GeminiService();

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  /// Send a message to the Gemini API
  Future<void> sendUserMessage(String text) async {
    final id = const Uuid().v4();

    // Add user message locally
    final userMsg = Message(id: id, text: text, sender: MessageSender.user);
    _messages.add(userMsg);

    _isLoading = true;
    notifyListeners();

    try {
      // Build context from previous messages (conversation history)
      final context = _messages.map((msg) {
        return {
          "role": msg.sender == MessageSender.user ? "user" : "model",
          "parts": [
            {"text": msg.text}
          ]
        };
      }).toList();

      // ✅ Call GeminiService with prompt + context
      final reply = await _service.sendMessage(text, context);

      // Add bot message locally
      final botMsg = Message(
        id: const Uuid().v4(),
        text: reply,
        sender: MessageSender.bot,
      );
      _messages.add(botMsg);
    } catch (e) {
      // In case of error, show it in chat
      final errMsg = 'Error: ${e.toString()}';
      _messages.add(
        Message(
          id: const Uuid().v4(),
          text: errMsg,
          sender: MessageSender.bot,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all messages
  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
