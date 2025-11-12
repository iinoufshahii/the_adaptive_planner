// lib/services/ai_service.dart (USING OPENROUTER)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_openai/dart_openai.dart'; // Backup method

class AiService {
  // --- OPENROUTER API KEY ---
  // Your OpenRouter API key (works with hundreds of models!)
  static const String _apiKey =
      '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';

  // Free models available on OpenRouter (using gpt-3.5-turbo in the implementation)

  // Static flag to track initialization
  static bool _isInitialized = false;

  // Configure OpenAI SDK to use OpenRouter endpoint
  AiService() {
    _ensureInitialized();
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      print('=== AI Service: Initializing OpenRouter configuration ===');
      OpenAI.apiKey = _apiKey;
      OpenAI.baseUrl = "https://openrouter.ai/api/v1"; // OpenRouter endpoint
      _isInitialized = true;
      print('=== AI Service: Configuration complete ===');
      print('API Key: ${_apiKey.substring(0, 20)}...');
      print('Base URL: https://openrouter.ai/api/v1');
    }
  }

  Future<Map<String, dynamic>> analyzeJournalEntry(String text) async {
    print('=== AI Service: Starting analysis ===');
    print('Text to analyze: ${text.length} characters');

    // Use HTTP method as primary since it's working reliably
    try {
      print('=== AI Service: Using direct HTTP method ===');
      final result = await _analyzeWithHttp(text);
      print('=== AI Service: HTTP method successful ===');
      return result;
    } catch (httpError) {
      print('=== AI Service: HTTP method failed: $httpError ===');
      print('=== AI Service: Trying dart_openai package as fallback ===');
    }

    try {
      // OpenAI uses a "system" message to set the AI's persona and rules.
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              'You are an empathetic AI journaling assistant. Your goal is to help the user reflect and feel understood. '
              'Respond ONLY with a valid JSON object with three keys: "mood", "feedback", and "actionableSteps". '
              'The "mood" must be a single string: "Positive", "Negative", "Neutral", or "Mixed". '
              'The "feedback" must be a 2-3 sentence supportive paragraph. '
              'The "actionableSteps" must be an array of 2-3 short, actionable suggestions as strings.'),
        ],
      );

      // The "user" message contains the actual journal entry text.
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(text),
        ],
      );

      print('=== AI Service: Sending request to OpenRouter ===');

      // Create the chat completion request using OpenRouter
      final response = await OpenAI.instance.chat.create(
        // Using a cost-effective model available through OpenRouter
        model: 'openai/gpt-3.5-turbo', // OpenRouter format: provider/model
        messages: [
          systemMessage,
          userMessage,
        ],
        temperature: 0.7, // Adds a touch of creativity to the feedback.
      );

      print('=== AI Service: Got response ===');
      print('Response object: ${response.toString()}');
      print('Choices length: ${response.choices.length}');

      if (response.choices.isEmpty) {
        print('ERROR: No choices in response');
        throw Exception('No choices in OpenAI response');
      }

      print('First choice: ${response.choices.first}');
      print('Message: ${response.choices.first.message}');
      print('Content array: ${response.choices.first.message.content}');

      // Extract the JSON string from the response
      final content = response.choices.first.message.content?.first.text;
      print('Raw AI response content: "$content"');
      print('Content length: ${content?.length ?? 0}');
      print('Content is null: ${content == null}');
      print('Content is empty: ${content?.isEmpty ?? true}');

      if (content != null && content.isNotEmpty) {
        try {
          // Decode the JSON string into a Dart Map
          final jsonResponse = jsonDecode(content);
          print('Parsed JSON response: $jsonResponse');

          final result = {
            'mood': jsonResponse['mood'] as String? ?? 'Neutral',
            'feedback':
                jsonResponse['feedback'] as String? ?? 'Thank you for sharing.',
            'actionableSteps': jsonResponse['actionableSteps'] != null
                ? List<String>.from(jsonResponse['actionableSteps'])
                // Ensure it's always a list, even if null in the response
                : <String>[],
          };

          print('=== AI Service: Analysis successful ===');
          return result;
        } catch (jsonError) {
          print('=== AI Service: JSON Parse Error ===');
          print('JSON Error: $jsonError');
          print('Content was: $content');
        }
      } else {
        print('=== AI Service: Empty response content ===');
      }
    } catch (e) {
      print('=== OPENAI AI ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      if (e is StackTrace) {
        print('Stack trace: $e');
      }
      print('=== Trying HTTP fallback ===');

      // Try the HTTP fallback method
      try {
        final result = await _analyzeWithHttp(text);
        print('HTTP fallback succeeded: $result');
        return result;
      } catch (httpError) {
        print('HTTP fallback also failed: $httpError');
      }
      print('========================');
    }

    // Return a default response on error
    print('=== AI Service: Returning error response ===');
    return {
      'mood': 'Error',
      'feedback': 'Could not analyze entry. Check debug console for details.',
      'actionableSteps': <String>[],
    };
  }

  // Fallback method using direct HTTP calls to OpenRouter
  Future<Map<String, dynamic>> _analyzeWithHttp(String text) async {
    print('=== AI Service: Trying HTTP fallback ===');

    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://localhost', // Required by OpenRouter
      'X-Title': 'Adaptive Planner', // Optional but recommended
    };

    final body = {
      'model': 'openai/gpt-3.5-turbo',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an empathetic AI journaling assistant. Your goal is to help the user reflect and feel understood. '
              'Respond ONLY with a valid JSON object with three keys: "mood", "feedback", and "actionableSteps". '
              'The "mood" must be a single string: "Positive", "Negative", "Neutral", or "Mixed". '
              'The "feedback" must be a 2-3 sentence supportive paragraph. '
              'The "actionableSteps" must be an array of 2-3 short, actionable suggestions as strings.'
        },
        {
          'role': 'user',
          'content': text,
        }
      ],
      'temperature': 0.7,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print('HTTP Response status: ${response.statusCode}');
      print('HTTP Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];

        if (content != null && content.isNotEmpty) {
          try {
            final jsonResponse = jsonDecode(content);
            return {
              'mood': jsonResponse['mood'] as String? ?? 'Neutral',
              'feedback': jsonResponse['feedback'] as String? ??
                  'Thank you for sharing.',
              'actionableSteps': jsonResponse['actionableSteps'] != null
                  ? List<String>.from(jsonResponse['actionableSteps'])
                  : <String>[],
            };
          } catch (jsonError) {
            print('JSON parse error in HTTP method: $jsonError');
          }
        }
      } else {
        print('HTTP request failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('HTTP request error: $e');
    }

    throw Exception('HTTP fallback failed');
  }

  // Test method to check if the AI service is working
  Future<bool> testConnection() async {
    print('=== AI Service: Testing connection ===');
    try {
      final testResult = await analyzeJournalEntry("I feel happy today!");
      print('Test result: $testResult');
      return testResult['mood'] != 'Error';
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
