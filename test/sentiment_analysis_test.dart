// test/sentiment_analysis_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_planner/services/hybrid_sentiment_service.dart';

void main() {
  group('OpenRouter AI Sentiment Analysis Tests', () {
    setUpAll(() async {
      // Initialize OpenRouter AI service before testing
      await HybridSentimentService.initialize();
    });

    test('should analyze sentiment with OpenRouter AI', () async {
      final result = await HybridSentimentService.analyzeSentiment(
        "I'm feeling amazing today! Everything is going perfectly and I'm so happy!",
      );
      
      expect(result['sentiment'], isA<String>());
      expect(result['confidence'], isA<double>());
      expect(result.containsKey('method'), isTrue);
    });

    test('should handle fallback when AI fails', () async {
      // This test may use fallback if AI service is unavailable
      final result = await HybridSentimentService.analyzeSentiment(
        "I'm really struggling today. Everything feels overwhelming.",
      );
      
      expect(result['sentiment'], isA<String>());
      expect(result['confidence'], isA<double>());
      expect(result.containsKey('method'), isTrue);
    });

    test('should handle empty text gracefully', () async {
      final result = await HybridSentimentService.analyzeSentiment('');
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('sentiment'), isTrue);
      expect(result.containsKey('confidence'), isTrue);
    });

    test('should provide enhanced analysis with recommendations', () async {
      final result = await HybridSentimentService.analyzeSentiment(
        "I'm excited about my project! The progress has been fantastic and I feel very motivated!",
      );
      
      expect(result['sentiment'], isA<String>());
      expect(result.containsKey('text_statistics'), isTrue);
      expect(result.containsKey('emotional_intensity'), isTrue);
      expect(result['text_statistics']['word_count'], greaterThan(0));
    });

    test('should calculate emotional intensity correctly', () async {
      final highIntensityResult = await HybridSentimentService.analyzeSentiment(
        "I AM SO EXCITED!!! This is AMAZING!!!",
      );
      
      final lowIntensityResult = await HybridSentimentService.analyzeSentiment(
        "I feel good today.",
      );
      
      expect(highIntensityResult['emotional_intensity'], 
             greaterThan(lowIntensityResult['emotional_intensity']));
    });

    test('should provide adaptive recommendations', () async {
      final result = await HybridSentimentService.analyzeSentiment(
        "I'm feeling overwhelmed and stressed with everything I need to do.",
      );
      
      final recommendations = HybridSentimentService.getAdaptiveRecommendations(result);
      
      expect(recommendations, isA<List<String>>());
      expect(recommendations.isNotEmpty, isTrue);
    });

    test('should list available methods', () {
      final methods = HybridSentimentService.getAvailableMethods();
      
      expect(methods, isA<List<String>>());
      expect(methods.contains('OpenRouter AI'), isTrue);
    });

    test('should generate sentiment summary', () async {
      final result = await HybridSentimentService.analyzeSentiment(
        "Today was a really great day!",
      );
      
      final summary = HybridSentimentService.getSentimentSummary(result);
      
      expect(summary, isA<String>());
      expect(summary.toLowerCase().contains('sentiment'), isTrue);
    });
  });
}