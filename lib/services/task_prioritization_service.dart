import '../models/task.dart';
import '../models/journal_entry.dart';
import '../models/mood_check_in.dart';

class TaskPrioritizationService {
  /// Reorders tasks based on current mood, energy levels, and priorities
  static List<Task> prioritizeTasks(
      List<Task> tasks, String? currentMood, DateTime? lastMoodUpdate) {
    print('=== Task Prioritization Service ===');
    print('Tasks to prioritize: ${tasks.length}');
    print('Current mood: $currentMood');
    print('Last mood update: $lastMoodUpdate');

    // Create a copy to avoid modifying the original list
    List<Task> prioritizedTasks = List<Task>.from(tasks);

    // Sort tasks based on adaptive algorithm
    prioritizedTasks.sort((a, b) {
      double scoreA = _calculateTaskScore(a, currentMood);
      double scoreB = _calculateTaskScore(b, currentMood);

      // Higher score = higher priority (sort descending)
      return scoreB.compareTo(scoreA);
    });

    print('=== Prioritization complete ===');
    return prioritizedTasks;
  }

  /// Calculate a priority score for a task based on mood and other factors
  static double _calculateTaskScore(Task task, String? currentMood) {
    double score = 0.0;

    // Base priority score (1-3 scale)
    switch (task.priority) {
      case TaskPriority.high:
        score += 30.0;
        break;
      case TaskPriority.medium:
        score += 20.0;
        break;
      case TaskPriority.low:
        score += 10.0;
        break;
    }

    // Deadline urgency (more urgent = higher score)
    DateTime now = DateTime.now();
    Duration timeUntilDeadline = task.deadline.difference(now);

    if (timeUntilDeadline.inDays <= 1) {
      score += 25.0; // Due today or overdue
    } else if (timeUntilDeadline.inDays <= 3) {
      score += 15.0; // Due within 3 days
    } else if (timeUntilDeadline.inDays <= 7) {
      score += 10.0; // Due within a week
    } else {
      score += 5.0; // Due later
    }

    // Mood-based energy matching
    if (currentMood != null) {
      double energyBonus = _calculateMoodEnergyMatch(
          currentMood, _taskEnergyToString(task.requiredEnergy));
      score += energyBonus;
    }

    // Completed tasks get lowest priority
    if (task.isCompleted) {
      score = -100.0;
    }

    return score;
  }

  /// Helper to convert TaskEnergyLevel enum to string
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

  /// Calculate energy level compatibility with current mood
  static double _calculateMoodEnergyMatch(String mood, String taskEnergyLevel) {
    Map<String, double> moodEnergyLevels = {
      'Positive': 15.0, // High energy
      'Mixed': 10.0, // Medium energy
      'Neutral': 5.0, // Low-medium energy
      'Negative': 0.0, // Low energy
    };

    Map<String, double> taskEnergyWeights = {
      'High': 15.0,
      'Medium': 10.0,
      'Low': 5.0,
    };

    double userEnergy = moodEnergyLevels[mood] ?? 5.0;
    double taskEnergyRequired = taskEnergyWeights[taskEnergyLevel] ?? 10.0;

    // Bonus for energy level matching (prefer tasks that match user's current energy)
    double energyDifference = (userEnergy - taskEnergyRequired).abs();
    double maxBonus = 15.0;

    // Closer energy match = higher bonus
    return maxBonus - (energyDifference * 0.5);
  }

  /// Get current mood from latest journal entry or mood check-in
  static String? getCurrentMood(
      List<JournalEntry> recentEntries, List<MoodCheckIn> recentCheckIns) {
    DateTime? latestJournalDate;
    DateTime? latestCheckInDate;
    String? mood;

    // Find latest journal entry with mood
    if (recentEntries.isNotEmpty) {
      var entriesWithMood = recentEntries
          .where((entry) => entry.mood != null && entry.mood!.isNotEmpty)
          .toList();

      if (entriesWithMood.isNotEmpty) {
        entriesWithMood.sort((a, b) => b.date.compareTo(a.date));
        latestJournalDate = entriesWithMood.first.date;
        mood = entriesWithMood.first.mood;
      }
    }

    // Find latest mood check-in
    if (recentCheckIns.isNotEmpty) {
      recentCheckIns.sort((a, b) => b.date.compareTo(a.date));
      latestCheckInDate = recentCheckIns.first.date;

      // Use check-in mood if it's more recent than journal mood
      if (latestJournalDate == null ||
          latestCheckInDate.isAfter(latestJournalDate)) {
        mood = recentCheckIns.first.mood;
      }
    }

    return mood;
  }
}
