import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/constants.dart';

class GeminiService {
  final Dio _dio;

  GeminiService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String> sendMessage(String prompt, List<Map<String, Object>> context) async {
    final apiKey = Constants.geminiApiKey;
    final url = Constants.baseUrl;

    if (apiKey.isEmpty) {
      throw Exception('Gemini API key missing. Set it in .env or via --dart-define');
    }

    print(apiKey);

    try {
      final resp = await _dio.post(
        url,
        data: jsonEncode({
          "contents": context + [{
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            }
          ],
        }),
        options: Options(headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        }),
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        // Gemini response structure
        return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "No response";
      }

      throw Exception('Failed with status ${resp.statusCode}');
    } on DioError catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
