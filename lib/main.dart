
// import 'package:ai_chat_bot/views/new_chatscreen.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'viewmodels/chat_viewmodel.dart';
// import 'views/chat_screen.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
   
//   );

//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => ChatViewModel(),
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Gemini AI ChatBot',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(useMaterial3: true),
//       home: const ChatScreen(),
//     );
//   }
// }



// lib/main.dart
import 'package:ai_chat_bot/login_screen.dart';
import 'package:ai_chat_bot/views/new_chatscreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'viewmodels/chat_viewmodel.dart';
import 'views/chat_screen.dart';
 // make sure this exists

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Force sign-out on every app start so auth screen shows first each launch
  // (This guarantees user must authenticate each app start.)
  try {
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    // ignore errors but log for debugging
    debugPrint('Sign-out on startup failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal AI ChatBot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

/// AuthGate listens to auth state and shows LoginScreen if not authenticated,
/// or ChatScreen if authenticated. Because we signed out above, user will
/// always start at LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // while waiting show loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          // not signed in -> show login
          return const LoginScreen();
        } else {
          // signed in -> show chat
          return const ChatScreen();
        }
      },
    );
  }
}

