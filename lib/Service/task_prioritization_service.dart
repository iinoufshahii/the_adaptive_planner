/// Task prioritization service for intelligent task ordering.
///
/// Reorders tasks based on current mood, energy levels, priorities, deadlines, and energy fit.
/// Provides a unified, well-documented prioritization algorithm optimized for productivity.
///
/// Features:
/// - Deadline-based urgency scoring
/// - Energy level matching (avoid fatigue, maximize flow state)
/// - Mood-aware task recommendations
/// - Completion status filtering
/// - Consistent scoring methodology

import '../models/journal_entry.dart';
import '../models/mood_check_in.dart';
import '../models/task.dart';

/// Service for intelligent task prioritization based on multiple factors.
///
/// Algorithm combines multiple scoring factors with weighted contributions:
/// - Priority (weight 30%): High/Medium/Low enum values
/// - Deadline Urgency (weight 40%): Time until deadline
/// - Energy Fit (weight 20%): Match between user energy and task requirements
/// - Mood Compatibility (weight 10%): Task suitability for current mood
class TaskPrioritizationService {
  /// Priority weight constants
  static const double _priorityWeight = 0.30;
  static const double _deadlineWeight = 0.40;
  static const double _energyFitWeight = 0.20;
  static const double _moodWeight = 0.10;

  /// Priority score mapping (normalized to 0-1)
  static const Map<TaskPriority, double> _priorityScores = {
    TaskPriority.high: 1.0,
    TaskPriority.medium: 0.6,
    TaskPriority.low: 0.3,
  };

  /// Reorders tasks based on current mood, energy levels, and priorities.
  ///
  /// Creates a copy of the original list and sorts in descending score order.
  /// Completed tasks are automatically deprioritized to the end.
  ///
  /// Parameters:
  /// - [tasks]: List of tasks to prioritize
  /// - [currentMood]: User's current mood (e.g., 'happy', 'stressed')
  /// - [currentEnergyLevel]: User's current energy (e.g., 'high', 'medium', 'low')
  /// - [lastMoodUpdate]: Timestamp of last mood check-in (for logging)
  ///
  /// Returns: New list of tasks sorted by priority (highest first)
  static List<Task> prioritizeTasks(
    List<Task> tasks,
    String? currentMood,
    String? currentEnergyLevel,
    DateTime? lastMoodUpdate,
  ) {
    print('=== Task Prioritization ===');
    print(
        'Tasks: ${tasks.length} | Mood: $currentMood | Energy: $currentEnergyLevel');

    // Create a copy to avoid modifying the original list
    final prioritizedTasks = List<Task>.from(tasks);

    // Sort by calculated priority score (descending)
    prioritizedTasks.sort((a, b) {
      final scoreA = _calculateTaskScore(a, currentMood, currentEnergyLevel);
      final scoreB = _calculateTaskScore(b, currentMood, currentEnergyLevel);
      return scoreB.compareTo(scoreA); // Higher score first
    });

    print(
        'Prioritization complete. Top task: ${prioritizedTasks.firstOrNull?.title}');
    return prioritizedTasks;
  }

  /// Calculate comprehensive priority score for a single task (0.0 - 1.0).
  ///
  /// Combines multiple factors with weighted contributions:
  /// 1. Base Priority (30%): Task's native priority level
  /// 2. Deadline Urgency (40%): How soon the task is due
  /// 3. Energy Fit (20%): Match between user and task energy requirements
  /// 4. Mood Compatibility (10%): How suitable the task is for current mood
  ///
  /// Completed tasks automatically receive a score of -1.0.
  ///
  /// Returns: Score between -1.0 (completed) and 1.0 (highest priority)
  static double _calculateTaskScore(
    Task task,
    String? currentMood,
    String? currentEnergyLevel,
  ) {
    // Completed tasks always get lowest priority
    if (task.isCompleted) {
      return -1.0;
    }

    // Calculate individual component scores (each 0-1 range)
    final priorityScore = _priorityScores[task.priority] ?? 0.6;
    final deadlineScore = _calculateDeadlineScore(task.deadline);
    final energyFitScore = _calculateEnergyFitScore(
      task.requiredEnergy,
      currentEnergyLevel,
    );
    final moodScore = _calculateMoodCompatibilityScore(
      task.requiredEnergy,
      currentMood,
    );

    // Weighted combination
    final totalScore = (priorityScore * _priorityWeight) +
        (deadlineScore * _deadlineWeight) +
        (energyFitScore * _energyFitWeight) +
        (moodScore * _moodWeight);

    return totalScore.clamp(0.0, 1.0);
  }

  /// Calculate deadline urgency score (0.0 - 1.0).
  ///
  /// Scoring:
  /// - Overdue or due today: 1.0
  /// - Due in 1-3 days: 0.8
  /// - Due in 3-7 days: 0.5
  /// - Due in 7+ days: 0.2
  /// - No deadline: 0.1
  ///
  /// Returns: Normalized urgency score (0-1)
  static double _calculateDeadlineScore(DateTime deadline) {
    final now = DateTime.now();
    final daysUntilDeadline = deadline.difference(now).inDays;

    if (daysUntilDeadline < 0) {
      return 1.0; // Overdue: maximum urgency
    } else if (daysUntilDeadline == 0) {
      return 1.0; // Due today: maximum urgency
    } else if (daysUntilDeadline <= 3) {
      return 0.8; // Due soon: high urgency
    } else if (daysUntilDeadline <= 7) {
      return 0.5; // Due this week: medium urgency
    } else {
      return 0.2; // Due later: low urgency
    }
  }

  /// Calculate energy fit score (0.0 - 1.0).
  ///
  /// Measures how well the user's current energy level matches task requirements.
  /// Perfect match (same level) scores 1.0.
  /// One level mismatch scores 0.5.
  /// Severe mismatch (user low, task high) scores 0.1.
  ///
  /// Parameters:
  /// - [taskEnergy]: Task's energy requirement
  /// - [userEnergyLevel]: User's current energy level (null treated as medium)
  ///
  /// Returns: Match score (0-1, higher = better fit)
  static double _calculateEnergyFitScore(
    TaskEnergyLevel taskEnergy,
    String? userEnergyLevel,
  ) {
    // Default to medium if not provided
    final userLevel = userEnergyLevel?.toLowerCase() ?? 'medium';
    final taskEnergyStr = _taskEnergyToString(taskEnergy).toLowerCase();

    // Perfect match: exact energy level
    if (userLevel == taskEnergyStr) {
      return 1.0;
    }

    // Adjacent levels (e.g., high user + medium task = acceptable)
    if ((userLevel == 'high' && taskEnergyStr == 'medium') ||
        (userLevel == 'medium' && taskEnergyStr == 'high') ||
        (userLevel == 'medium' && taskEnergyStr == 'low') ||
        (userLevel == 'low' && taskEnergyStr == 'medium')) {
      return 0.5;
    }

    // Severe mismatch (e.g., low user + high task = not ideal)
    return 0.1;
  }

  /// Calculate mood-based task compatibility score (0.0 - 1.0).
  ///
  /// Recommends task types based on current mood:
  /// - Stressed/Sad: Best with low-energy tasks (0.8) or medium (0.5)
  /// - Happy/Energetic: Best with high-energy tasks (0.9) or medium (0.6)
  /// - Angry: Best with high-energy physical tasks (0.8) or medium (0.5)
  /// - Neutral: No preference (0.6)
  ///
  /// Parameters:
  /// - [taskEnergy]: Task's energy requirement
  /// - [userMood]: User's current mood (null treated as neutral)
  ///
  /// Returns: Compatibility score (0-1)
  static double _calculateMoodCompatibilityScore(
    TaskEnergyLevel taskEnergy,
    String? userMood,
  ) {
    final mood = userMood?.toLowerCase() ?? 'neutral';
    final taskEnergyStr = _taskEnergyToString(taskEnergy).toLowerCase();

    switch (mood) {
      case 'stressed':
      case 'sad':
        // Best: low-energy tasks, second: medium-energy
        if (taskEnergyStr == 'low') return 0.8;
        if (taskEnergyStr == 'medium') return 0.5;
        if (taskEnergyStr == 'high') return 0.2;
        break;

      case 'happy':
      case 'energetic':
      case 'excited':
        // Best: high-energy tasks, second: medium-energy
        if (taskEnergyStr == 'high') return 0.9;
        if (taskEnergyStr == 'medium') return 0.6;
        if (taskEnergyStr == 'low') return 0.3;
        break;

      case 'angry':
        // Good for high-energy physical tasks
        if (taskEnergyStr == 'high') return 0.8;
        if (taskEnergyStr == 'medium') return 0.5;
        if (taskEnergyStr == 'low') return 0.3;
        break;

      case 'neutral':
      default:
        // No strong preference
        if (taskEnergyStr == 'medium') return 0.7;
        return 0.6;
    }

    return 0.6; // Fallback
  }

  /// Convert TaskEnergyLevel enum to string representation.
  ///
  /// Returns: String value ('High', 'Medium', or 'Low')
  static String _taskEnergyToString(TaskEnergyLevel energy) {
    switch (energy) {
      case TaskEnergyLevel.high:
        return 'High';
      case TaskEnergyLevel.medium:
        return 'Medium';
      case TaskEnergyLevel.low:
        return 'Low';
    }
  }

  /// Get current mood from latest journal entry or mood check-in.
  ///
  /// Prioritizes mood check-ins over journal entries if more recent.
  ///
  /// Parameters:
  /// - [recentEntries]: Recent journal entries
  /// - [recentCheckIns]: Recent mood check-ins
  ///
  /// Returns: Latest mood string, or null if none found
  static String? getCurrentMood(
    List<JournalEntry> recentEntries,
    List<MoodCheckIn> recentCheckIns,
  ) {
    DateTime? latestJournalDate;
    DateTime? latestCheckInDate;
    String? mood;

    // Find latest journal entry with mood
    if (recentEntries.isNotEmpty) {
      final entriesWithMood = recentEntries
          .where((entry) => entry.mood != null && entry.mood!.isNotEmpty)
          .toList();

      if (entriesWithMood.isNotEmpty) {
        entriesWithMood.sort((a, b) => b.date.compareTo(a.date));
        latestJournalDate = entriesWithMood.first.date;
        mood = entriesWithMood.first.mood;
      }
    }

    // Find latest mood check-in and use if more recent
    if (recentCheckIns.isNotEmpty) {
      recentCheckIns.sort((a, b) => b.date.compareTo(a.date));
      latestCheckInDate = recentCheckIns.first.date;

      if (latestJournalDate == null ||
          latestCheckInDate.isAfter(latestJournalDate)) {
        mood = recentCheckIns.first.mood;
      }
    }

    return mood;
  }
}
