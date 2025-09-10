
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
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_scrollController.hasClients) return;
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeOut,
//       );
//     });
//   }

//   String _formatDateTime(DateTime dt) {
//     final local = dt.toLocal();
//     final date = "${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}";
//     final time = "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
//     return "$date $time";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<ChatViewModel>(context);

//     // scroll when messages change
//     WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gemini AI ChatBot'),
//       ),
//       drawer: Drawer(
//         child: SafeArea(
//           child: Column(
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.add),
//                 title: const Text('New Chat'),
//                 onTap: () {
//                   // close drawer first, then create new chat safely
//                   Navigator.of(context).pop();
//                   Future.microtask(() async {
//                     await vm.createNewChat();
//                   });
//                 },
//               ),
//               const Divider(height: 1),
//               Expanded(
//                 child: StreamBuilder<List<ChatSummary>>(
//                   stream: vm.chatSummariesStream(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     final chats = snapshot.data ?? [];
//                     if (chats.isEmpty) {
//                       return const Center(child: Text('No previous chats'));
//                     }
//                     return ListView.separated(
//                       itemCount: chats.length,
//                       separatorBuilder: (_, __) => const Divider(height: 0.5),
//                       itemBuilder: (context, index) {
//                         final c = chats[index];
//                         return ListTile(
//                           leading: const Icon(Icons.chat_bubble_outline),
//                           title: Text(c.title.isEmpty ? 'Chat' : c.title),
//                           subtitle: Text(
//                             c.lastMessage.isEmpty ? 'No messages yet' : c.lastMessage,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           trailing: Text(_formatDateTime(c.updatedAt), style: const TextStyle(fontSize: 11)),
//                           onTap: () {
//                             // close drawer before loading chat to avoid deactivated widget errors
//                             Navigator.of(context).pop();
//                             Future.microtask(() async {
//                               await vm.loadChat(c.id);
//                             });
//                           },
//                           onLongPress: () async {
//                             final confirmed = await showDialog<bool>(
//                               context: context,
//                               builder: (ctx) => AlertDialog(
//                                 title: const Text('Delete chat?'),
//                                 content: const Text('Delete this chat and all messages?'),
//                                 actions: [
//                                   TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
//                                   TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
//                                 ],
//                               ),
//                             );
//                             if (confirmed == true) {
//                               await vm.deleteChat(c.id);
//                             }
//                           },
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: vm.messages.isEmpty
//                 ? const Center(child: Text('No messages yet — open menu to start a new chat'))
//                 : ListView.builder(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     itemCount: vm.messages.length,
//                     itemBuilder: (context, index) {
//                       final Message msg = vm.messages[index];
//                       final bool isUser = msg.sender == MessageSender.user;
//                       return Align(
//                         alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
//                           margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 msg.text,
//                                 style: TextStyle(color: isUser ? Colors.white : Colors.black87),
//                               ),
//                               const SizedBox(height: 6),
//                               Text(
//                                 _formatDateTime(msg.createdAt),
//                                 style: TextStyle(
//                                   color: isUser ? Colors.white70 : Colors.black54,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//           if (vm.isLoading)
//             const Padding(
//               padding: EdgeInsets.symmetric(vertical: 6),
//               child: LinearProgressIndicator(),
//             ),
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       textInputAction: TextInputAction.send,
//                       onSubmitted: (_) async {
//                         final text = _controller.text.trim();
//                         if (text.isEmpty) return;
//                         await vm.sendUserMessage(text);
//                         _controller.clear();
//                         _scrollToBottom();
//                       },
//                       decoration: InputDecoration(
//                         hintText: 'Type a message...',
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     icon: const Icon(Icons.send),
//                     color: vm.isLoading ? Colors.grey : Colors.blue,
//                     onPressed: vm.isLoading
//                         ? null
//                         : () async {
//                             final text = _controller.text.trim();
//                             if (text.isEmpty) return;
//                             await vm.sendUserMessage(text);
//                             _controller.clear();
//                             _scrollToBottom();
//                           },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// lib/views/chat_screen.dart
import 'package:ai_chat_bot/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../viewmodels/chat_viewmodel.dart';
import '../models/message.dart';
 // ensure this import path matches your project

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
    final date = "${local.year.toString().padLeft(4,'0')}-${local.month.toString().padLeft(2,'0')}-${local.day.toString().padLeft(2,'0')}";
    final time = "${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}";
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
                  Navigator.of(context).pop();
                  Future.microtask(() => vm.createNewChat());
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
                            Navigator.of(context).pop();
                            Future.microtask(() async => vm.loadChat(c.id));
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
                            if (confirmed == true) await vm.deleteChat(c.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 1),
              // Logout button
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  // close drawer then sign out
                  Navigator.of(context).pop();
                  await FirebaseAuth.instance.signOut();
                  // After sign out, AuthGate will send user to LoginScreen
                  // But to be extra-safe (if you don't use AuthGate), you can:
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
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
                              Text(msg.text, style: TextStyle(color: isUser ? Colors.white : Colors.black87)),
                              const SizedBox(height: 6),
                              Text(
                                _formatDateTime(msg.createdAt),
                                style: TextStyle(color: isUser ? Colors.white70 : Colors.black54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (vm.isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: LinearProgressIndicator()),
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
