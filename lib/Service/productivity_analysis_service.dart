// lib/services/productivity_analysis_service.dart

/// Model for completed task data used in productivity analysis
class CompletedTask {
  final String taskId;
  final DateTime completedAt;
  final double taskEnergyRequirement; // 1=low, 2=medium, 3=high
  final double taskDifficulty; // Difficulty level (higher = harder)
  final String mood; // User's mood when completing the task
  final double journalSentiment; // Journal sentiment (-1 to 1)

  const CompletedTask({
    required this.taskId,
    required this.completedAt,
    required this.taskEnergyRequirement,
    required this.taskDifficulty,
    required this.mood,
    required this.journalSentiment,
  });
}

/// Result of productivity analysis
class ProductivityResult {
  final String bestTimeOfDayLabel; // e.g., "Morning", "Evening"
  final TimeOfDayRange bestTimeRange; // Enum for programmatic use
  final String bestDayOfWeek; // e.g., "Monday", "Friday"
  final Map<String, double> timeScores; // Time bucket -> average score
  final Map<String, double> dayScores; // Day -> average score

  const ProductivityResult({
    required this.bestTimeOfDayLabel,
    required this.bestTimeRange,
    required this.bestDayOfWeek,
    required this.timeScores,
    required this.dayScores,
  });
}

/// Enum for time of day ranges
enum TimeOfDayRange {
  earlyMorning, // 5-8
  morning, // 8-11
  midday, // 11-14
  afternoon, // 14-17
  evening, // 17-21
  night, // 21-24
  lateNight, // 00-5
}

/// Service for analyzing productivity patterns from completed tasks
class ProductivityAnalysisService {
  /// Analyze completed tasks to identify productivity patterns
  ProductivityResult analyze(List<CompletedTask> completedTasks) {
    if (completedTasks.isEmpty) {
      return ProductivityResult(
        bestTimeOfDayLabel: 'No data',
        bestTimeRange: TimeOfDayRange.evening, // Default
        bestDayOfWeek: 'No data',
        timeScores: {},
        dayScores: {},
      );
    }

    // Initialize buckets
    final timeBuckets = <String, List<double>>{
      'Early Morning': [],
      'Morning': [],
      'Midday': [],
      'Afternoon': [],
      'Evening': [],
      'Night': [],
      'Late Night': [],
    };

    final dayBuckets = <String, List<double>>{
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };

    // Process each completed task
    for (final task in completedTasks) {
      final productivityScore = _calculateProductivityScore(task);
      final timeBucket = _getTimeBucket(task.completedAt);
      final dayBucket = _getDayBucket(task.completedAt);

      final timeList = timeBuckets[timeBucket];
      final dayList = dayBuckets[dayBucket];

      if (timeList != null) {
        timeList.add(productivityScore);
      }
      if (dayList != null) {
        dayList.add(productivityScore);
      }
    }

    // Calculate average scores for each bucket
    final timeScores = <String, double>{};
    for (final entry in timeBuckets.entries) {
      if (entry.value.isNotEmpty) {
        timeScores[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      } else {
        timeScores[entry.key] = 0.0;
      }
    }

    final dayScores = <String, double>{};
    for (final entry in dayBuckets.entries) {
      if (entry.value.isNotEmpty) {
        dayScores[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      } else {
        dayScores[entry.key] = 0.0;
      }
    }

    // Find best time and day
    final bestTimeEntry =
        timeScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    final bestDayEntry =
        dayScores.entries.reduce((a, b) => a.value > b.value ? a : b);

    final bestTimeRange = _timeBucketToRange(bestTimeEntry.key);

    return ProductivityResult(
      bestTimeOfDayLabel: bestTimeEntry.key,
      bestTimeRange: bestTimeRange,
      bestDayOfWeek: bestDayEntry.key,
      timeScores: timeScores,
      dayScores: dayScores,
    );
  }

  /// Calculate productivity score for a completed task
  double _calculateProductivityScore(CompletedTask task) {
    // Base score
    double score = 1.0;

    // Energy adjustment (taskEnergyRequirement is 1=low, 2=med, 3=high)
    final energyAdj = task.taskEnergyRequirement * 0.5;
    score += energyAdj;

    // Mood adjustment
    final moodAdj = _getMoodAdjustment(task.mood);
    score += moodAdj;

    // Sentiment adjustment
    final sentAdj = task.journalSentiment * 0.5;
    score += sentAdj;

    // Difficulty penalty
    final difficultyPenalty = 1.0 / task.taskDifficulty;
    score -= difficultyPenalty;

    // Ensure score doesn't go below 0
    return score > 0 ? score : 0;
  }

  /// Get mood adjustment value
  double _getMoodAdjustment(String mood) {
    final moodLower = mood.toLowerCase();
    switch (moodLower) {
      case 'happy':
      case 'energetic':
        return 1.0;
      case 'neutral':
        return 0.5;
      case 'stressed':
      case 'sad':
        return 0.0;
      default:
        return 0.5; // Default to neutral
    }
  }

  /// Get time bucket for a given datetime
  String _getTimeBucket(DateTime dateTime) {
    final hour = dateTime.hour;

    if (hour >= 5 && hour < 8) {
      return 'Early Morning';
    } else if (hour >= 8 && hour < 11) {
      return 'Morning';
    } else if (hour >= 11 && hour < 14) {
      return 'Midday';
    } else if (hour >= 14 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else if (hour >= 21 && hour < 24) {
      return 'Night';
    } else {
      return 'Late Night'; // 00-5
    }
  }

  /// Get day bucket for a given datetime
  String _getDayBucket(DateTime dateTime) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[dateTime.weekday - 1]; // weekday is 1-7 (Mon-Sun)
  }

  /// Convert time bucket string to TimeOfDayRange enum
  TimeOfDayRange _timeBucketToRange(String bucket) {
    switch (bucket) {
      case 'Early Morning':
        return TimeOfDayRange.earlyMorning;
      case 'Morning':
        return TimeOfDayRange.morning;
      case 'Midday':
        return TimeOfDayRange.midday;
      case 'Afternoon':
        return TimeOfDayRange.afternoon;
      case 'Evening':
        return TimeOfDayRange.evening;
      case 'Night':
        return TimeOfDayRange.night;
      case 'Late Night':
        return TimeOfDayRange.lateNight;
      default:
        return TimeOfDayRange.evening; // Default
    }
  }
}
