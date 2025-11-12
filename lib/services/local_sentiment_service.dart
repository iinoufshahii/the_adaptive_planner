// lib/services/local_sentiment_service.dart

import 'dart:math';
import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';  // Will be uncommented when TF packages are added
import 'model_downloader.dart';

class LocalSentimentService {
  // static Interpreter? _interpreter;  // Commented out for now
  static List<String>? _vocabulary;
  static bool _isInitialized = false;
  static bool _modelAvailable = false;

  // Initialize the sentiment analysis service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('=== Local Sentiment Service: Initializing ===');
      
      // Check if TensorFlow model is available
      _modelAvailable = await ModelDownloader.isModelDownloaded();
      
      if (_modelAvailable) {
        print('=== TensorFlow model available ===');
        // TODO: Initialize TensorFlow Lite model when packages are added
        // _interpreter = await Interpreter.fromAsset('assets/models/sentiment_model.tflite');
      }
      
      // Load vocabulary (if available)
      await _loadVocabulary();
      
      _isInitialized = true;
      print('=== Local Sentiment Service: Initialized (rule-based mode) ===');
    } catch (e) {
      print('=== Local Sentiment Service: Failed to initialize - $e ===');
      _isInitialized = true; // Still allow rule-based analysis
    }
  }

  // Load vocabulary for text tokenization
  static Future<void> _loadVocabulary() async {
    try {
      final vocabString = await rootBundle.loadString('assets/models/vocabulary.txt');
      _vocabulary = vocabString.split('\n').where((line) => line.isNotEmpty).toList();
      print('=== Vocabulary loaded: ${_vocabulary!.length} words ===');
    } catch (e) {
      print('=== Vocabulary loading failed: $e ===');
      _vocabulary = null;
    }
  }

  // Main sentiment analysis function
  static Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    await initialize();

    if (_modelAvailable && _isInitialized) {
      // TODO: Use TensorFlow model when available
      return await _analyzeWithModel(text);
    } else {
      // Use rule-based analysis
      return _analyzeWithRules(text);
    }
  }

  // TensorFlow Lite model-based analysis (placeholder for future implementation)
  static Future<Map<String, dynamic>> _analyzeWithModel(String text) async {
    // TODO: Implement TensorFlow Lite analysis when packages are added
    print('=== TensorFlow model not yet implemented, using rule-based analysis ===');
    return _analyzeWithRules(text);
    
    /* Future implementation with TensorFlow Lite:
    try {
      // Preprocess the text (tokenization, padding, etc.)
      final inputTokens = _preprocessText(text);
      
      // Prepare input tensor
      final input = [inputTokens];
      
      // Prepare output tensor  
      final output = List.generate(1, (index) => List.filled(3, 0.0)); // [negative, neutral, positive]
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Process results
      final scores = output[0];
      final negativeScore = scores[0];
      final neutralScore = scores[1];
      final positiveScore = scores[2];
      
      // Determine overall sentiment
      String sentiment;
      double confidence;
      
      if (positiveScore > negativeScore && positiveScore > neutralScore) {
        sentiment = 'positive';
        confidence = positiveScore;
      } else if (negativeScore > neutralScore) {
        sentiment = 'negative';
        confidence = negativeScore;
      } else {
        sentiment = 'neutral';
        confidence = neutralScore;
      }

      return {
        'sentiment': sentiment,
        'confidence': confidence,
        'scores': {
          'negative': negativeScore,
          'neutral': neutralScore,
          'positive': positiveScore,
        },
        'method': 'tensorflow_lite'
      };
    } catch (e) {
      print('=== TensorFlow analysis failed: $e ===');
      return _analyzeWithRules(text);
    }
    */
  }

  // Preprocess text for the model (will be used when TensorFlow is implemented)
  /* 
  static List<int> _preprocessText(String text, {int maxLength = 256}) {
    if (_vocabulary == null) {
      // Simple character-based encoding as fallback
      final chars = text.toLowerCase().codeUnits;
      final normalized = chars.map((c) => c % 256).toList();
      
      if (normalized.length > maxLength) {
        return normalized.sublist(0, maxLength);
      } else {
        return normalized + List.filled(maxLength - normalized.length, 0);
      }
    }

    // Tokenize text using vocabulary
    final words = text.toLowerCase().split(RegExp(r'[^a-zA-Z0-9]+'));
    final tokens = <int>[];
    
    for (final word in words) {
      final index = _vocabulary!.indexOf(word);
      tokens.add(index >= 0 ? index : 1); // 1 for unknown tokens
    }
    
    // Pad or truncate to maxLength
    if (tokens.length > maxLength) {
      return tokens.sublist(0, maxLength);
    } else {
      return tokens + List.filled(maxLength - tokens.length, 0);
    }
  }
  */

  // Rule-based sentiment analysis fallback
  static Map<String, dynamic> _analyzeWithRules(String text) {
    print('=== Using rule-based sentiment analysis ===');
    
    final lowerText = text.toLowerCase();
    
    // Positive words
    final positiveWords = [
      'happy', 'good', 'great', 'excellent', 'amazing', 'wonderful', 'fantastic',
      'love', 'like', 'enjoy', 'excited', 'thrilled', 'delighted', 'pleased',
      'accomplished', 'successful', 'proud', 'confident', 'optimistic', 'hopeful',
      'grateful', 'thankful', 'blessed', 'content', 'satisfied', 'peaceful'
    ];
    
    // Negative words
    final negativeWords = [
      'sad', 'bad', 'terrible', 'awful', 'horrible', 'hate', 'dislike',
      'angry', 'frustrated', 'annoyed', 'disappointed', 'worried', 'anxious',
      'stressed', 'overwhelmed', 'tired', 'exhausted', 'depressed', 'upset',
      'difficult', 'hard', 'challenging', 'struggling', 'failed', 'lost'
    ];
    
    // Count positive and negative words
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (lowerText.contains(word)) {
        positiveCount++;
      }
    }
    
    for (final word in negativeWords) {
      if (lowerText.contains(word)) {
        negativeCount++;
      }
    }
    
    // Calculate sentiment
    String sentiment;
    double confidence;
    
    final totalWords = text.split(RegExp(r'\s+')).length;
    final sentimentStrength = (positiveCount - negativeCount) / max(totalWords, 1);
    
    if (sentimentStrength > 0.1) {
      sentiment = 'positive';
      confidence = min(0.8, 0.5 + sentimentStrength);
    } else if (sentimentStrength < -0.1) {
      sentiment = 'negative';
      confidence = min(0.8, 0.5 - sentimentStrength);
    } else {
      sentiment = 'neutral';
      confidence = 0.6;
    }
    
    return {
      'sentiment': sentiment,
      'confidence': confidence,
      'scores': {
        'positive': positiveCount / max(totalWords, 1),
        'negative': negativeCount / max(totalWords, 1),
        'neutral': 1.0 - ((positiveCount + negativeCount) / max(totalWords, 1)),
      },
      'method': 'rule_based',
      'word_counts': {
        'positive': positiveCount,
        'negative': negativeCount,
        'total': totalWords,
      }
    };
  }

  // Clean up resources
  static void dispose() {
    // TODO: Close TensorFlow interpreter when implemented
    // _interpreter?.close();
    // _interpreter = null;
    _isInitialized = false;
    _modelAvailable = false;
  }
}
