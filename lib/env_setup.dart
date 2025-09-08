import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadEnv() async {
  try {
    // Explicitly tell dotenv to load .env file
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Prevent crash if .env not found
    print("⚠️ Warning: .env file not found. Error: $e");
  }
}
