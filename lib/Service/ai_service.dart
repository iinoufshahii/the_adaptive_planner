/// AI-powered journal entry analysis service using OpenRouter API.
///
/// Analyzes journal entries using gpt-3.5-turbo to provide:
/// - Mood classification (Positive, Negative, Neutral, Mixed)
/// - Empathetic feedback
/// - Actionable suggestions
///
/// Uses OpenRouter as the API provider for cost-effective model access.
/// Implements retry logic with HTTP fallback for reliability.

import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for analyzing journal entries using AI.
///
/// Uses OpenRouter API with gpt-3.5-turbo model to provide sentiment analysis,
/// mood detection, and actionable feedback for journal entries.
class AiService {
  /// OpenRouter API key for authentication
  static const String _apiKey =
      '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';

  /// Static flag to track if service is initialized
  static bool _isInitialized = false;

  /// OpenRouter API endpoint URL
  static const String _openRouterEndpoint = 'https://openrouter.ai/api/v1';

  /// OpenRouter chat completions endpoint
  static const String _chatCompletionUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Model to use for analysis
  static const String _modelId = 'openai/gpt-3.5-turbo';

  /// Temperature for response generation (0.7 for balanced creativity)
  static const double _temperature = 0.7;

  /// System prompt for journal analysis
  static const String _systemPrompt =
      'You are an empathetic AI journaling assistant. Your goal is to help the user reflect and feel understood. '
      'Respond ONLY with a valid JSON object with three keys: "mood", "feedback", and "actionableSteps". '
      'The "mood" must be a single string: "Positive", "Negative", "Neutral", or "Mixed". '
      'The "feedback" must be a 2-3 sentence supportive paragraph. '
      'The "actionableSteps" must be an array of 2-3 short, actionable suggestions as strings.';

  /// Initialize OpenAI SDK with OpenRouter configuration
  AiService() {
    _ensureInitialized();
  }

  /// Ensures OpenAI SDK is initialized only once
  static void _ensureInitialized() {
    if (!_isInitialized) {
      debugPrint('=== AI Service: Initializing OpenRouter configuration ===');
      OpenAI.apiKey = _apiKey;
      OpenAI.baseUrl = _openRouterEndpoint;
      _isInitialized = true;
      debugPrint('=== AI Service: Configuration complete ===');
    }
  }

  /// Analyzes journal entry text and returns mood, feedback, and suggestions.
  ///
  /// Attempts to analyze using OpenAI SDK first, with HTTP fallback.
  /// Returns a map with keys: 'mood', 'feedback', 'actionableSteps'.
  ///
  /// Parameters:
  ///   - [text]: The journal entry text to analyze
  ///
  /// Returns:
  ///   A map containing mood classification, supportive feedback, and suggestions.
  ///   Returns error response if analysis fails.
  Future<Map<String, dynamic>> analyzeJournalEntry(String text) async {
    debugPrint('=== AI Service: Starting analysis ===');
    debugPrint('Text to analyze: ${text.length} characters');

    // Try HTTP method first (more reliable)
    try {
      debugPrint('=== AI Service: Using direct HTTP method ===');
      final result = await _analyzeWithHttp(text);
      debugPrint('=== AI Service: HTTP method successful ===');
      return result;
    } catch (httpError) {
      debugPrint('=== AI Service: HTTP method failed: $httpError ===');
      debugPrint('=== AI Service: Trying dart_openai package as fallback ===');
    }

    try {
      // Create system message with analysis instructions
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(_systemPrompt),
        ],
      );

      // Create user message with journal entry text
      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(text),
        ],
      );

      debugPrint('=== AI Service: Sending request to OpenRouter ===');

      // Send chat completion request
      final response = await OpenAI.instance.chat.create(
        model: _modelId,
        messages: [systemMessage, userMessage],
        temperature: _temperature,
      );

      debugPrint('=== AI Service: Got response ===');

      // Validate response has choices
      if (response.choices.isEmpty) {
        debugPrint('ERROR: No choices in response');
        throw Exception('No choices in OpenAI response');
      }

      // Extract JSON content from response
      final content = response.choices.first.message.content?.first.text;
      debugPrint('Raw AI response content: "$content"');

      if (content != null && content.isNotEmpty) {
        try {
          // Parse JSON from AI response
          final jsonResponse = jsonDecode(content);
          debugPrint('Parsed JSON response: $jsonResponse');

          return {
            'mood': jsonResponse['mood'] as String? ?? 'Neutral',
            'feedback':
                jsonResponse['feedback'] as String? ?? 'Thank you for sharing.',
            'actionableSteps': jsonResponse['actionableSteps'] != null
                ? List<String>.from(jsonResponse['actionableSteps'])
                : <String>[],
          };
        } catch (jsonError) {
          debugPrint('=== AI Service: JSON Parse Error: $jsonError ===');
        }
      }
    } catch (e) {
      debugPrint('=== AI Service: OpenAI Error: $e ===');

      // Try HTTP fallback
      try {
        debugPrint('=== AI Service: Trying HTTP fallback ===');
        final result = await _analyzeWithHttp(text);
        debugPrint('HTTP fallback succeeded');
        return result;
      } catch (httpError) {
        debugPrint('HTTP fallback also failed: $httpError');
      }
    }

    // Return default error response
    debugPrint('=== AI Service: Returning error response ===');
    return {
      'mood': 'Error',
      'feedback': 'Could not analyze entry. Please try again later.',
      'actionableSteps': <String>[],
    };
  }

  /// Analyzes journal entry using direct HTTP calls to OpenRouter.
  ///
  /// Fallback method when OpenAI SDK fails.
  /// Makes direct REST API calls to OpenRouter endpoint.
  ///
  /// Parameters:
  ///   - [text]: The journal entry text to analyze
  ///
  /// Returns:
  ///   A map with mood analysis results
  ///
  /// Throws:
  ///   Exception if HTTP request fails
  Future<Map<String, dynamic>> _analyzeWithHttp(String text) async {
    debugPrint('=== AI Service: Using HTTP method ===');

    final url = Uri.parse(_chatCompletionUrl);
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://localhost',
      'X-Title': 'Adaptive Planner',
    };

    final body = {
      'model': _modelId,
      'messages': [
        {
          'role': 'system',
          'content': _systemPrompt,
        },
        {
          'role': 'user',
          'content': text,
        }
      ],
      'temperature': _temperature,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('HTTP Response status: ${response.statusCode}');

      // Check for successful response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];

        if (content != null && content.isNotEmpty) {
          try {
            // Parse JSON analysis from response
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
            debugPrint('JSON parse error: $jsonError');
          }
        }
      } else {
        debugPrint('HTTP request failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('HTTP request error: $e');
    }

    throw Exception('HTTP analysis failed');
  }

  /// Tests OpenRouter connection with a simple analysis.
  ///
  /// Returns true if connection and analysis succeed, false otherwise.
  Future<bool> testConnection() async {
    debugPrint('=== AI Service: Testing connection ===');
    try {
      final testResult = await analyzeJournalEntry('I feel happy today!');
      debugPrint('Test result: $testResult');
      return testResult['mood'] != 'Error';
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
}
