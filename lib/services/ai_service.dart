// lib/services/ai_service.dart (USING OPENAI)

import 'dart:convert';
import 'package:dart_openai/dart_openai.dart'; // Use the OpenAI package

class AiService {
  // --- IMPORTANT ---
  // Replace with your secret key from the OpenAI Platform dashboard.
  static const String _apiKey = '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';

  // The constructor now sets the static API key for the OpenAI package.
  AiService() {
    OpenAI.apiKey = _apiKey;
  }

  Future<Map<String, dynamic>> analyzeJournalEntry(String text) async {
    // OpenAI uses a "system" message to set the AI's persona and rules.
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.system,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          'You are an empathetic AI journaling assistant. Your goal is to help the user reflect and feel understood. '
          'Respond ONLY with a valid JSON object with three keys: "mood", "feedback", and "actionableSteps". '
          'The "mood" must be a single string: "Positive", "Negative", "Neutral", or "Mixed". '
          'The "feedback" must be a 2-3 sentence supportive paragraph. '
          'The "actionableSteps" must be an array of 2-3 short, actionable suggestions as strings.'
        ),
      ],
    );

    // The "user" message contains the actual journal entry text.
    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.user,
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(text),
      ],
    );

    try {
      // Create the chat completion request
      final response = await OpenAI.instance.chat.create(
        // gpt-3.5-turbo is fast, cheap, and powerful.
        model: 'gpt-3.5-turbo',
        // This tells the model to guarantee a JSON output.
        // If your dart_openai version supports responseFormat, use the following line:
        // responseFormat: {"type": "json_object"},
        messages: [
          systemMessage,
          userMessage,
        ],
        temperature: 0.7, // Adds a touch of creativity to the feedback.
      );

      // Extract the JSON string from the response
      final content = response.choices.first.message.content?.first.text;

      if (content != null) {
        // Decode the JSON string into a Dart Map
        final jsonResponse = jsonDecode(content);
        return {
          'mood': jsonResponse['mood'] as String? ?? 'Neutral',
          'feedback': jsonResponse['feedback'] as String? ?? 'Thank you for sharing.',
          'actionableSteps': jsonResponse['actionableSteps'] != null
              ? List<String>.from(jsonResponse['actionableSteps'])
              // Ensure it's always a list, even if null in the response
              : <String>[],
        };
      }
    } catch (e) {
      print('--- OPENAI AI ERROR ---');
      print(e.toString());
      print('-----------------------');
    }

    // Return a default response on error
    return {
      'mood': 'Error',
      'feedback': 'Could not analyze entry. Check debug console for details.',
      'actionableSteps': <String>[],
    };
  }
}