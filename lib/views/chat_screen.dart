// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../viewmodels/chat_viewmodel.dart';
// import '../widgets/message_bubble.dart';

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final vm = context.watch<ChatViewModel>();

//     return Scaffold(
//       appBar: AppBar(title: const Text('AI Chat')),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               reverse: false,
//               padding: const EdgeInsets.all(8),
//               itemCount: vm.messages.length,
//               itemBuilder: (context, index) {
//                 final msg = vm.messages[index];
//                 return MessageBubble(message: msg);
//               },
//             ),
//           ),
//           if (vm.isLoading) const LinearProgressIndicator(),
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _controller,
//                       decoration: const InputDecoration(hintText: 'Type a message'),
//                       onSubmitted: (text) => _send(vm),
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: vm.isLoading ? null : () => _send(vm),
//                     icon: const Icon(Icons.send),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _send(ChatViewModel vm) {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//     _controller.clear();

//     print(text);
//     vm.sendUserMessage(text);
//   }
// }
