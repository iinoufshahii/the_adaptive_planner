// lib/services/hybrid_sentiment_service.dart

import 'dart:math';
import 'ai_service.dart';

/// A simplified sentiment analysis service using only OpenRouter AI
class HybridSentimentService {
  static bool _initialized = false;
  
  /// Initialize OpenRouter AI service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('=== Sentiment Service: Initializing OpenRouter AI ===');
      // AI service initializes itself when first used
      _initialized = true;
      print('=== Sentiment Service: Initialization complete ===');
    } catch (e) {
      print('=== Sentiment Service: Initialization failed: $e ===');
      _initialized = false;
    }
  }

  /// Analyze sentiment using OpenRouter AI only
  static Future<Map<String, dynamic>> analyzeSentiment(String text, {
    bool preferLocal = false, // Ignored - only AI available
    bool allowAI = true,
  }) async {
    print('=== OpenRouter AI Sentiment Analysis Starting ===');
    print('Text length: ${text.length}');
    
    await initialize();
    Map<String, dynamic>? result;
    
    // Use OpenRouter AI for sentiment analysis
    try {
      print('=== Analyzing with OpenRouter AI ===');
      final aiService = AiService();
      final aiResult = await aiService.analyzeJournalEntry(text);
      
      result = _convertAIResultToStandardFormat(aiResult);
      print('=== OpenRouter AI analysis successful ===');
    } catch (e) {
      print('=== OpenRouter AI analysis failed: $e ===');
      // Create fallback result if AI fails
      result = {
        'sentiment': 'neutral',
        'confidence': 0.5,
        'scores': {'positive': 0.33, 'negative': 0.33, 'neutral': 0.34},
        'method': 'fallback',
        'error': e.toString(),
      };
    }
    
    // Enhance result with additional insights
    return _enhanceResult(result, text);
  }

  /// Convert AI service result to standard sentiment format
  static Map<String, dynamic> _convertAIResultToStandardFormat(Map<String, dynamic> aiResult) {
    final mood = aiResult['mood']?.toString().toLowerCase() ?? 'neutral';
    
    // Map mood to sentiment
    String sentiment;
    double confidence;
    
    switch (mood) {
      case 'happy':
      case 'excited':
      case 'grateful':
      case 'confident':
        sentiment = 'positive';
        confidence = 0.85;
        break;
      case 'sad':
      case 'angry':
      case 'frustrated':
      case 'anxious':
      case 'stressed':
        sentiment = 'negative';
        confidence = 0.85;
        break;
      default:
        sentiment = 'neutral';
        confidence = 0.7;
    }
    
    return {
      'sentiment': sentiment,
      'confidence': confidence,
      'scores': _generateScoresFromSentiment(sentiment, confidence),
      'method': 'openrouter_ai',
      'ai_feedback': aiResult['feedback'] ?? '',
      'actionable_steps': aiResult['actionableSteps'] ?? <String>[],
      'detected_mood': mood,
    };
  }

  /// Generate probability scores from sentiment and confidence
  static Map<String, double> _generateScoresFromSentiment(String sentiment, double confidence) {
    switch (sentiment) {
      case 'positive':
        return {
          'positive': confidence,
          'negative': (1 - confidence) * 0.2,
          'neutral': (1 - confidence) * 0.8,
        };
      case 'negative':
        return {
          'positive': (1 - confidence) * 0.2,
          'negative': confidence,
          'neutral': (1 - confidence) * 0.8,
        };
      default:
        return {
          'positive': (1 - confidence) * 0.4,
          'negative': (1 - confidence) * 0.4,
          'neutral': confidence + (1 - confidence) * 0.2,
        };
    }
  }

  /// Enhance result with additional insights and recommendations
  static Map<String, dynamic> _enhanceResult(Map<String, dynamic> result, String text) {
    // Calculate emotional intensity
    final intensity = _calculateEmotionalIntensity(text);
    
    // Analyze text statistics
    final textStats = _analyzeTextStatistics(text);
    
    // Generate adaptive recommendations
    final recommendations = getAdaptiveRecommendations(result);
    
    return {
      ...result,
      'emotional_intensity': intensity,
      'text_statistics': textStats,
      'adaptive_recommendations': recommendations,
      'analysis_timestamp': DateTime.now().toIso8601String(),
      'enhanced': true,
    };
  }

  /// Analyze basic text statistics
  static Map<String, dynamic> _analyzeTextStatistics(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).toList();
    
    return {
      'word_count': words.length,
      'sentence_count': sentences.length,
      'character_count': text.length,
      'avg_word_length': words.isEmpty ? 0 : words.map((w) => w.length).reduce((a, b) => a + b) / words.length,
      'exclamation_count': '!'.allMatches(text).length,
      'question_count': '?'.allMatches(text).length,
    };
  }

  /// Calculate emotional intensity based on text markers
  static double _calculateEmotionalIntensity(String text) {
    double intensity = 0.5; // Base intensity
    
    // Punctuation markers
    intensity += '!'.allMatches(text).length * 0.1; // Each ! adds intensity
    intensity += '?'.allMatches(text).length * 0.05; // Questions add some intensity
    
    // All caps words
    final capsWords = text.split(RegExp(r'\s+')).where((w) => 
        w.length > 2 && w == w.toUpperCase() && RegExp(r'[A-Z]').hasMatch(w)
    ).length;
    intensity += capsWords * 0.15;
    
    // Multiple exclamation marks
    intensity += '!!'.allMatches(text).length * 0.2;
    
    // Emotional intensifiers
    final intensifiers = ['very', 'extremely', 'incredibly', 'absolutely', 'completely'];
    for (final word in intensifiers) {
      intensity += text.toLowerCase().split(RegExp(r'\W+')).where((w) => w == word).length * 0.1;
    }
    
    return min(1.0, intensity); // Cap at 1.0
  }

  /// Get sentiment summary text
  static String getSentimentSummary(Map<String, dynamic> result) {
    final sentiment = result['sentiment'] as String;
    final confidence = ((result['confidence'] as double) * 100).toStringAsFixed(1);
    final method = result['method'] as String;
    
    String methodName;
    switch (method) {
      case 'openrouter_ai':
        methodName = 'OpenRouter AI';
        break;
      case 'fallback':
        methodName = 'Fallback';
        break;
      default:
        methodName = 'OpenRouter AI';
    }
    
    return '$sentiment sentiment detected with $confidence% confidence using $methodName analysis';
  }

  /// Generate adaptive recommendations based on sentiment analysis
  static List<String> getAdaptiveRecommendations(Map<String, dynamic> result) {
    final sentiment = result['sentiment'] as String;
    final confidence = result['confidence'] as double;
    final intensity = result['emotional_intensity'] as double? ?? 0.5;
    
    final recommendations = <String>[];
    
    switch (sentiment) {
      case 'positive':
        if (intensity > 0.7) {
          recommendations.addAll([
            '🚀 High energy detected! Perfect time for challenging tasks',
            '🎯 Consider tackling your most important goals',
            '💪 Your mood suggests you can handle complex projects',
          ]);
        } else {
          recommendations.addAll([
            '😊 Good mood detected - great for productive work',
            '📋 Consider organizing your task list',
            '🤝 Good time for collaborative activities',
          ]);
        }
        break;
        
      case 'negative':
        if (intensity > 0.7) {
          recommendations.addAll([
            '🌧️ Difficult emotions detected - be gentle with yourself',
            '🧘 Consider taking a short break or doing breathing exercises',
            '📝 Focus on simple, routine tasks to build momentum',
          ]);
        } else {
          recommendations.addAll([
            '💙 Low mood noted - consider lighter tasks',
            '☕ Maybe take a short break before continuing',
            '🎵 Some background music might help',
          ]);
        }
        break;
        
      default:
        recommendations.addAll([
          '⚖️ Neutral mood - steady progress possible',
          '📊 Good time for planning and organizing',
          '🎯 Consider setting clear goals for the day',
        ]);
    }
    
    // Add confidence-based recommendations
    if (confidence < 0.6) {
      recommendations.add('💭 Mixed emotions detected - check in with yourself regularly');
    }
    
    return recommendations;
  }

  /// Get available analysis methods
  static List<String> getAvailableMethods() {
    return ['OpenRouter AI'];
  }

  /// Cleanup method
  static void dispose() {
    _initialized = false;
  }
}