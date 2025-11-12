import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class TaskBreakdownService {
  static const String _apiKey =
      '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';

  /// Break down a complex task into smaller, manageable subtasks using AI
  static Future<List<String>> breakdownTask(String taskTitle,
      String? taskDescription, TaskPriority priority, DateTime deadline) async {
    print('=== Task Breakdown Service ===');
    print('Breaking down task: $taskTitle');

    try {
      // Construct detailed prompt for AI
      String prompt =
          _buildBreakdownPrompt(taskTitle, taskDescription, priority, deadline);

      // Call OpenRouter API
      final response = await _callOpenRouterAPI(prompt);

      // Parse and validate subtasks
      List<String> subtasks = _parseSubtasks(response);

      print('=== Generated ${subtasks.length} subtasks ===');
      return subtasks;
    } catch (e) {
      print('=== Task Breakdown Error: $e ===');
      // Return fallback subtasks
      return _generateFallbackSubtasks(taskTitle, taskDescription);
    }
  }

  /// Build a comprehensive prompt for task breakdown
  static String _buildBreakdownPrompt(String title, String? description,
      TaskPriority priority, DateTime deadline) {
    DateTime now = DateTime.now();
    int daysUntilDeadline = deadline.difference(now).inDays;

    String priorityString = priority.name.toUpperCase();
    String descriptionText = description?.isNotEmpty == true
        ? description!
        : "No additional details provided.";

    return '''
You are a productivity assistant helping break down complex tasks into manageable subtasks.

TASK TO BREAKDOWN:
Title: "$title"
Description: $descriptionText
Priority: $priorityString
Days until deadline: $daysUntilDeadline

INSTRUCTIONS:
1. Break this task into 3-6 actionable subtasks
2. Make each subtask specific, measurable, and achievable
3. Order subtasks logically (what should be done first)
4. Consider the deadline and priority level
5. Each subtask should take 15 minutes to 2 hours maximum
6. Use action verbs (Research, Create, Review, Contact, etc.)

RESPOND WITH ONLY A JSON ARRAY:
["Subtask 1", "Subtask 2", "Subtask 3", "etc"]

Example format:
["Research topic and gather sources", "Create outline with main points", "Write first draft", "Review and edit content", "Format final document"]
''';
  }

  /// Make HTTP request to OpenRouter API
  static Future<String> _callOpenRouterAPI(String prompt) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'HTTP-Referer': 'https://adaptive-planner.com',
      'X-Title': 'Adaptive Planner - Task Breakdown',
    };

    final body = {
      'model': 'openai/gpt-3.5-turbo',
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.3, // Lower temperature for more consistent results
      'max_tokens': 400,
    };

    print('=== Sending request to OpenRouter ===');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices'][0]['message']['content'];
      print('AI Response: $content');
      return content;
    } else {
      print('API Error: ${response.body}');
      throw Exception(
          'OpenRouter API failed with status ${response.statusCode}');
    }
  }

  /// Parse AI response and extract subtasks
  static List<String> _parseSubtasks(String aiResponse) {
    try {
      // Clean the response - remove any markdown formatting
      String cleanedResponse = aiResponse.trim();

      // Remove code block markers if present
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse =
            cleanedResponse.replaceAll('```json', '').replaceAll('```', '');
      }

      // Parse JSON array
      List<dynamic> jsonArray = jsonDecode(cleanedResponse);

      // Convert to string list and validate
      List<String> subtasks = jsonArray
          .map((item) => item.toString().trim())
          .where((task) => task.isNotEmpty)
          .take(8) // Limit to max 8 subtasks
          .toList();

      if (subtasks.isEmpty) {
        throw Exception('No valid subtasks found in response');
      }

      return subtasks;
    } catch (e) {
      print('=== Parse Error: $e ===');
      print('Raw response was: $aiResponse');

      // Try to extract subtasks from plain text response
      return _extractSubtasksFromText(aiResponse);
    }
  }

  /// Fallback: Extract subtasks from plain text response
  static List<String> _extractSubtasksFromText(String response) {
    List<String> lines = response
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    List<String> subtasks = [];

    for (String line in lines) {
      // Look for numbered or bulleted lists
      RegExp listPattern = RegExp(r'^[\d\-\*\•]\s*\.?\s*(.+)$');
      Match? match = listPattern.firstMatch(line);

      if (match != null) {
        String subtask = match.group(1)?.trim() ?? '';
        if (subtask.isNotEmpty && subtasks.length < 6) {
          subtasks.add(subtask);
        }
      } else if (line.length > 10 && line.length < 100 && subtasks.length < 6) {
        // Add lines that look like tasks (reasonable length)
        subtasks.add(line);
      }
    }

    return subtasks.isNotEmpty ? subtasks : _getDefaultSubtasks();
  }

  /// Generate fallback subtasks when AI fails
  static List<String> _generateFallbackSubtasks(
      String title, String? description) {
    print('=== Generating fallback subtasks ===');

    // Basic task breakdown patterns
    if (title.toLowerCase().contains('research') ||
        title.toLowerCase().contains('study')) {
      return [
        'Define research objectives and scope',
        'Gather relevant sources and materials',
        'Review and analyze key information',
        'Organize findings and take notes',
        'Summarize results and conclusions'
      ];
    }

    if (title.toLowerCase().contains('project') ||
        title.toLowerCase().contains('assignment')) {
      return [
        'Plan project structure and timeline',
        'Gather necessary resources',
        'Complete initial draft or prototype',
        'Review and refine work',
        'Finalize and submit deliverables'
      ];
    }

    if (title.toLowerCase().contains('presentation') ||
        title.toLowerCase().contains('report')) {
      return [
        'Research topic and gather content',
        'Create outline and structure',
        'Develop main content sections',
        'Design visuals or formatting',
        'Practice and final review'
      ];
    }

    // Generic fallback
    return [
      'Break down the main task requirements',
      'Gather necessary resources and information',
      'Complete the core work',
      'Review and refine the results',
      'Finalize and complete the task'
    ];
  }

  /// Default subtasks when all else fails
  static List<String> _getDefaultSubtasks() {
    return [
      'Plan and organize approach',
      'Complete the main work',
      'Review and finalize'
    ];
  }
}
