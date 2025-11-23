/// User status model for real-time wellness tracking and task personalization.
///
/// This file provides:
/// - UserStatus: Aggregated emotional and energy state for smart recommendations
///
/// Features:
/// - Real-time emotional state tracking
/// - Numeric energy scale for consistent processing
/// - Mood and sentiment analysis integration
/// - Factory constructor for mood check-in conversion
/// - Immutable-style updates via copyWith()
library;

/// Model aggregating current user emotional and energy status for task prioritization and recommendations.
///
/// Combines energy level, mood, and journal sentiment to create holistic user context.
/// Used to inform smart task scheduling, personalized recommendations, and wellness tracking.
///
/// Key features:
/// - Energy scale conversion (categorical to 0-10 numeric)
/// - Mood and sentiment tracking for emotional intelligence
/// - Factory from mood check-in data for seamless integration
/// - Support for wellness state inference in task algorithms
class UserStatus {
  /// Current energy level on a 0-10 scale (0=exhausted, 10=peak energy).
  ///
  /// Used to match tasks with appropriate difficulty and duration.
  /// Values:
  /// - 0-2: Exhausted, basic tasks only
  /// - 3-4: Low energy, lighter workload recommended
  /// - 5-7: Medium energy, standard workload appropriate
  /// - 8-10: High energy, challenging tasks recommended
  final double currentEnergy;

  /// Current mood as a string (e.g., 'happy', 'sad', 'neutral', 'stressed', 'angry').
  ///
  /// Used for emotion-aware task recommendations and user context.
  /// Influences task prioritization and break suggestions.
  final String? mood;

  /// Journal sentiment score on a -1 to 1 scale (-1=very negative, 0=neutral, 1=very positive).
  ///
  /// Derived from journal entry analysis for holistic well-being assessment.
  /// Supports long-term trend analysis and wellness insights.
  final double? journalSentiment;

  /// Constructor for creating a UserStatus instance with current emotional state.
  ///
  /// Parameters:
  /// - [currentEnergy]: Required energy level (0-10 scale)
  /// - [mood]: Optional current mood string
  /// - [journalSentiment]: Optional sentiment score from journal analysis
  const UserStatus({
    required this.currentEnergy,
    this.mood,
    this.journalSentiment,
  });

  /// Factory constructor: Create UserStatus from mood check-in data.
  ///
  /// Converts categorical energy level strings to numeric 0-10 scale for consistent processing.
  /// Provides seamless integration between mood check-in and status tracking systems.
  ///
  /// Energy level conversion:
  /// - 'low' → 3.0 (low energy range)
  /// - 'medium' → 6.0 (medium energy range)
  /// - 'high' → 9.0 (high energy range)
  /// - null/unknown → 5.0 (default medium)
  ///
  /// Parameters:
  /// - [mood]: Optional mood string from mood check-in
  /// - [energyLevel]: Optional energy level string ('low', 'medium', 'high')
  ///
  /// Returns: UserStatus with mood and energy converted to standard scales
  factory UserStatus.fromMoodCheckIn({
    required String? mood,
    required String? energyLevel,
  }) {
    // Initialize energy value to middle ground (medium)
    double energyValue = 5.0; // Default to 5.0 (medium on 0-10 scale)

    // Conditional: Convert energy level string to numeric scale
    if (energyLevel != null) {
      // Switch on lowercase energy level string for case-insensitive comparison
      switch (energyLevel.toLowerCase()) {
        case 'low':
          energyValue = 3.0; // Low energy = 3 on 0-10 scale
          break;
        case 'medium':
          energyValue = 6.0; // Medium energy = 6 on 0-10 scale
          break;
        case 'high':
          energyValue = 9.0; // High energy = 9 on 0-10 scale
          break;
        // Implicit default: unmatched values remain at 5.0
      }
    }

    return UserStatus(
      currentEnergy: energyValue, // Use converted numeric energy value
      mood: mood,
    );
  }

  /// Creates a copy of this UserStatus with optionally updated fields.
  ///
  /// Enables immutable-style updates without rebuilding the entire object.
  /// Omitted parameters retain original values.
  ///
  /// Example: `newStatus = status.copyWith(currentEnergy: 8.0)`
  ///
  /// Parameters:
  /// - [currentEnergy]: Optional new energy level
  /// - [mood]: Optional new mood string
  /// - [journalSentiment]: Optional new sentiment score
  ///
  /// Returns: New UserStatus instance with updated fields
  UserStatus copyWith({
    double? currentEnergy,
    String? mood,
    double? journalSentiment,
  }) {
    return UserStatus(
      currentEnergy: currentEnergy ?? this.currentEnergy,
      mood: mood ?? this.mood,
      journalSentiment: journalSentiment ?? this.journalSentiment,
    );
  }

  /// Provides readable string representation for debugging.
  ///
  /// Includes all relevant status metrics in human-readable format.
  ///
  /// Returns: String with energy, mood, and sentiment values
  @override
  String toString() {
    return 'UserStatus(energy: $currentEnergy, mood: $mood, sentiment: $journalSentiment)';
  }
}
