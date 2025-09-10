




// // lib/views/chat_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../viewmodels/chat_viewmodel.dart';
// import '../models/message.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   String? currentChatId;

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<ChatViewModel>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Gemini AI ChatBot"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete_forever, color: Colors.red),
//             tooltip: "Clear Chat",
//             onPressed: () {
//               vm.clear();
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Chat cleared")),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: FutureBuilder<List<String>>(
//           future: vm.fetchChatIds(),
//           builder: (context, snapshot) {
//             return ListView(
//               children: [
//                 const DrawerHeader(
//                   decoration: BoxDecoration(color: Colors.blue),
//                   child: Text("Chats", style: TextStyle(color: Colors.white)),
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.add),
//                   title: const Text("New Chat"),
//                   onTap: () {
//                     setState(() {
//                       currentChatId =
//                           DateTime.now().millisecondsSinceEpoch.toString();
//                     });
//                     vm.clear();
//                     Navigator.pop(context);
//                   },
//                 ),
//                 if (snapshot.hasData)
//                   ...snapshot.data!.map(
//                     (id) => ListTile(
//                       leading: const Icon(Icons.chat),
//                       title: Text("Chat $id"),
//                       onTap: () {
//                         setState(() {
//                           currentChatId = id;
//                         });
//                         vm.loadChat(id);
//                         Navigator.pop(context);
//                       },
//                     ),
//                   ),
//               ],
//             );
//           },
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: vm.messages.length,
//               itemBuilder: (context, index) {
//                 final msg = vm.messages[index];
//                 return Align(
//                   alignment: msg.sender == MessageSender.user
//                       ? Alignment.centerRight
//                       : Alignment.centerLeft,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     margin:
//                         const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                     decoration: BoxDecoration(
//                       color: msg.sender == MessageSender.user
//                           ? Colors.blueAccent
//                           : Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       msg.text,
//                       style: TextStyle(
//                         color: msg.sender == MessageSender.user
//                             ? Colors.white
//                             : Colors.black,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           if (vm.isLoading)
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: CircularProgressIndicator(),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: "Type your message...",
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send, color: Colors.blue),
//                   onPressed: () {
//                     if (_controller.text.trim().isNotEmpty) {
//                       vm.sendUserMessage(
//                         _controller.text.trim(),
//                         chatId: currentChatId,
//                       );
//                       _controller.clear();
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// lib/views/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final date = "${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}";
    final time = "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
    return "$date $time";
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ChatViewModel>(context);

    // scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI ChatBot'),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New Chat'),
                onTap: () {
                  // close drawer first, then create new chat safely
                  Navigator.of(context).pop();
                  Future.microtask(() async {
                    await vm.createNewChat();
                  });
                },
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<ChatSummary>>(
                  stream: vm.chatSummariesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final chats = snapshot.data ?? [];
                    if (chats.isEmpty) {
                      return const Center(child: Text('No previous chats'));
                    }
                    return ListView.separated(
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const Divider(height: 0.5),
                      itemBuilder: (context, index) {
                        final c = chats[index];
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(c.title.isEmpty ? 'Chat' : c.title),
                          subtitle: Text(
                            c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(_formatDateTime(c.updatedAt), style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            // close drawer before loading chat to avoid deactivated widget errors
                            Navigator.of(context).pop();
                            Future.microtask(() async {
                              await vm.loadChat(c.id);
                            });
                          },
                          onLongPress: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete chat?'),
                                content: const Text('Delete this chat and all messages?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await vm.deleteChat(c.id);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.messages.isEmpty
                ? const Center(child: Text('No messages yet — open menu to start a new chat'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, index) {
                      final Message msg = vm.messages[index];
                      final bool isUser = msg.sender == MessageSender.user;
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDateTime(msg.createdAt),
                                style: TextStyle(
                                  color: isUser ? Colors.white70 : Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: LinearProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) async {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        await vm.sendUserMessage(text);
                        _controller.clear();
                        _scrollToBottom();
                      },
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: vm.isLoading ? Colors.grey : Colors.blue,
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            final text = _controller.text.trim();
                            if (text.isEmpty) return;
                            await vm.sendUserMessage(text);
                            _controller.clear();
                            _scrollToBottom();
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

