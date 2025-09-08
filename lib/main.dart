import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/env_setup.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await loadEnv(); // loads .env (safe for development only)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const ChatScreen(),
      ),
    );
  }
}
