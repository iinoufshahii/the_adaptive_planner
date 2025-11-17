/// Analytics screen displaying productivity patterns and task completion stats.
/// Shows weekly productivity trends, best times/days for work, sentiment streak,
/// and overall task completion progress. Uses caching to prevent unnecessary rebuilds.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/journal_entry.dart';
import '../models/task.dart';
import '../Service/mood_service.dart';
import '../Service/productivity_analysis_service.dart';
import '../Widgets/Responsive_widget.dart';

/// Analytics screen displaying productivity patterns and task completion stats.
///
/// Shows weekly productivity trends, best times/days for work, sentiment streak,
/// and overall task completion progress. Uses caching to prevent unnecessary rebuilds.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final Future<int> _sentimentStreakFuture;
  late final Future<ProductivityResult?> _productivityResultFuture;

  @override
  void initState() {
    super.initState();
    // Initialize futures once - prevents refetching on every rebuild
    _sentimentStreakFuture = _loadSentimentStreak();
    _productivityResultFuture = _loadProductivityPatterns();
  }

  /// Loads sentiment streak based on consecutive days with mood check-ins.
  ///
  /// Uses the MoodService to calculate the current mood check-in streak,
  /// which indicates consecutive days of emotional well-being tracking.
  Future<int> _loadSentimentStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      final moodService = MoodService();
      return await moodService.currentStreak(user.uid);
    } catch (e) {
      debugPrint('Error loading sentiment streak: $e');
      return 0;
    }
  }

  /// Calculates average sentiment from journal entries based on mood and AI feedback.
  ///
  /// Returns a value between 0.0 (very negative) and 1.0 (very positive).
  /// Uses mood categorization and presence of positive keywords in AI feedback.
  double _calculateAverageSentiment(List<JournalEntry> entries) {
    if (entries.isEmpty) return 0.5; // neutral default

    double totalSentiment = 0.0;
    for (final entry in entries) {
      double entrySentiment = 0.5; // neutral default

      // Score based on mood
      if (entry.mood != null) {
        final mood = entry.mood!.toLowerCase();
        if (mood.contains('happy') ||
            mood.contains('excited') ||
            mood.contains('positive')) {
          entrySentiment = 0.8;
        } else if (mood.contains('sad') ||
            mood.contains('angry') ||
            mood.contains('negative')) {
          entrySentiment = 0.2;
        } else if (mood.contains('calm') || mood.contains('neutral')) {
          entrySentiment = 0.5;
        }
      }

      // Adjust based on AI feedback sentiment
      if (entry.aiFeedback != null) {
        final feedback = entry.aiFeedback!.toLowerCase();
        if (feedback.contains('positive') ||
            feedback.contains('great') ||
            feedback.contains('excellent')) {
          entrySentiment = (entrySentiment + 0.8) / 2;
        } else if (feedback.contains('negative') ||
            feedback.contains('difficult') ||
            feedback.contains('challenge')) {
          entrySentiment = (entrySentiment + 0.3) / 2;
        }
      }

      totalSentiment += entrySentiment;
    }

    return totalSentiment / entries.length;
  }

  /// Loads productivity patterns from completed tasks.
  ///
  /// Analyzes completed tasks and calculates best times/days for productivity.
  Future<ProductivityResult?> _loadProductivityPatterns() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get completed tasks - use cache to prevent constant Firestore reads
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .where('isCompleted', isEqualTo: true)
          .get();

      // Fetch latest mood and journal sentiment once
      final latestMoodSnapshot = await FirebaseFirestore.instance
          .collection('moodCheckIns')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(1)
          .get();
      final latestMood = latestMoodSnapshot.docs.isNotEmpty
          ? latestMoodSnapshot.docs.first.data()['mood'] as String
          : 'neutral';

      final journalsSnapshot = await FirebaseFirestore.instance
          .collection('journals')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .limit(10)
          .get();
      final journals = journalsSnapshot.docs
          .map((doc) => JournalEntry.fromMap(doc.data(), doc.id))
          .toList();
      final averageJournalSentiment =
          _calculateAverageSentiment(journals); // 0.0 to 1.0

      final completedTasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        final task = Task.fromFirestore(data, doc.id);
        // Use current time as completion time since we don't have completedAt
        // In a real implementation, you'd want to add a completedAt field
        final completedAt = DateTime.now();

        return CompletedTask(
          taskId: task.id!,
          completedAt: completedAt,
          taskEnergyRequirement: task.requiredEnergy == TaskEnergyLevel.high
              ? 3.0
              : task.requiredEnergy == TaskEnergyLevel.medium
                  ? 2.0
                  : 1.0,
          taskDifficulty: task.priority == TaskPriority.high
              ? 3.0
              : task.priority == TaskPriority.medium
                  ? 2.0
                  : 1.0,
          mood: latestMood,
          journalSentiment: averageJournalSentiment,
        );
      }).toList();

      final analysisService = ProductivityAnalysisService();
      return analysisService.analyze(completedTasks);
    } catch (e) {
      debugPrint('Error loading productivity patterns: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(fontSize: ResponsiveUtils.getTitleFontSize(context)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 1400 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Weekly Productivity Hours'),
                  SizedBox(height: padding * 0.75),
                  _buildWeeklyProductivityChart(context),
                  SizedBox(height: padding),
                  _buildSectionTitle(context, 'Productivity Patterns'),
                  SizedBox(height: padding * 0.75),
                  FutureBuilder<ProductivityResult?>(
                    future: _productivityResultFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: ResponsiveUtils.isTablet(context) ? 140 : 120,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Text(
                          'Unable to load productivity data',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getBodyFontSize(context),
                          ),
                        );
                      }
                      return _buildProductivityPatterns(
                          context, snapshot.data!);
                    },
                  ),
                  SizedBox(height: padding),
                  _buildSectionTitle(context, 'Mood & Sentiment Analysis'),
                  SizedBox(height: padding * 0.75),
                  _buildMoodSentimentChart(context),
                  SizedBox(height: padding),
                  _buildSectionTitle(context, 'Journal Sentiment Streak'),
                  SizedBox(height: padding * 0.75),
                  FutureBuilder<int>(
                    future: _sentimentStreakFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: ResponsiveUtils.isTablet(context) ? 100 : 80,
                          child:
                              const Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildSentimentStreak(context, snapshot.data ?? 0);
                    },
                  ),
                  SizedBox(height: padding),
                  _buildSectionTitle(context, 'Task Completion'),
                  SizedBox(height: padding * 0.75),
                  _buildTaskCompletionChart(context),
                  SizedBox(height: padding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a section title with consistent styling and responsive font sizes.
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: ResponsiveUtils.getTitleFontSize(context),
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildWeeklyProductivityChart(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Sign in to view productivity stats');
    }
    final now = DateTime.now();
    // ISO week start (Monday)
    final weekStart = now
        .subtract(Duration(days: (now.weekday + 6) % 7)); // Monday of this week
    final weekEnd = weekStart.add(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('focusSessions')
          .where('userId', isEqualTo: user.uid)
          .where('start',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(weekStart.year, weekStart.month, weekStart.day)))
          .where('start',
              isLessThan: Timestamp.fromDate(
                  DateTime(weekEnd.year, weekEnd.month, weekEnd.day)))
          .orderBy('start')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final docs = snapshot.data?.docs ?? [];
        final dailyMinutes = List<int>.filled(7, 0);
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final ts = data['start'];
          if (ts is Timestamp) {
            final dt = ts.toDate();
            final dayIndex = dt
                .difference(
                    DateTime(weekStart.year, weekStart.month, weekStart.day))
                .inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              final mins = (data['durationMinutes'] as num?)?.toInt() ?? 0;
              dailyMinutes[dayIndex] += mins;
            }
          }
        }
        // Convert to hours (double)
        final dailyHours = dailyMinutes.map((m) => m / 60.0).toList();
        final maxY =
            (dailyHours.reduce((a, b) => a > b ? a : b) + 0.5).clamp(1, 24);
        final spots = <FlSpot>[
          for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), dailyHours[i])
        ];
        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final theme = Theme.of(context);
        final lineColor = theme.colorScheme.primary;

        final cardPadding = ResponsiveUtils.getCardPadding(context);
        final chartHeight = ResponsiveUtils.isWeb(context)
            ? 320.0
            : ResponsiveUtils.isTablet(context)
                ? 280.0
                : 250.0;

        return SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getCardPadding(context)),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY.toDouble(),
                  gridData: FlGridData(
                      show: true,
                      horizontalInterval:
                          (maxY / 4).clamp(0.5, double.infinity)),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          labels[value.toInt()],
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the sentiment streak card displaying the current streak with responsive sizing.
  Widget _buildSentimentStreak(BuildContext context, int sentimentStreak) {
    final theme = Theme.of(context);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(ResponsiveUtils.getCardPadding(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: iconSize,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: cardPadding * 0.75),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sentiment Streak',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: cardPadding * 0.25),
                  Text(
                    '$sentimentStreak days',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the productivity patterns card showing best day and best time with responsive layout.
  Widget _buildProductivityPatterns(
      BuildContext context, ProductivityResult productivityResult) {
    final theme = Theme.of(context);
    final cardPadding = ResponsiveUtils.getCardPadding(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWeb = ResponsiveUtils.isWeb(context);
    final spacing = cardPadding * 0.75;
    final iconSize = ResponsiveUtils.getIconSize(context) * 0.6;

    final cardWidget = (
        {required String title,
        required String value,
        required IconData icon}) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ResponsiveUtils.getCardPadding(context)),
        ),
        color: theme.cardTheme.color,
        child: Padding(
          padding: EdgeInsets.all(cardPadding * 0.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: spacing * 0.5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: ResponsiveUtils.getSmallFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: spacing * 0.25),
              Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: isWeb
                      ? 24
                      : isMobile
                          ? 18
                          : 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    };

    // Side by side on all screen sizes
    return Row(
      children: [
        Expanded(
          child: cardWidget(
            title: 'Best Day',
            value: productivityResult.bestDayOfWeek,
            icon: Icons.calendar_today,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: cardWidget(
            title: 'Best Time',
            value: productivityResult.bestTimeOfDayLabel,
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

  /// Builds mood and sentiment analysis chart showing recent mood check-ins and journal sentiment
  Widget _buildMoodSentimentChart(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Text('Sign in to view mood data');

    final theme = Theme.of(context);
    final cardPadding = ResponsiveUtils.getCardPadding(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardPadding),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Trends & Journal Sentiment',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getTitleFontSize(context) * 0.85,
              ),
            ),
            SizedBox(height: cardPadding),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('moodCheckIns')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, moodSnapshot) {
                if (moodSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (moodSnapshot.hasError) {
                  return Text('Error loading mood data: ${moodSnapshot.error}');
                }

                final moodDocs = moodSnapshot.data?.docs ?? [];
                if (moodDocs.isEmpty) {
                  return SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'No mood check-ins yet',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                // Mood mapping for chart
                const moodOrder = [
                  'sad',
                  'stressed',
                  'angry',
                  'neutral',
                  'calm',
                  'happy'
                ];
                int moodToValue(String? mood) {
                  if (mood == null) return 3;
                  final idx = moodOrder.indexOf(mood.toLowerCase());
                  return idx == -1 ? 3 : idx + 1;
                }

                // Process mood data (reverse to show chronologically)
                final moodList = moodDocs.reversed.toList();
                final spots = <FlSpot>[];
                for (int i = 0; i < moodList.length; i++) {
                  final data = moodList[i].data() as Map<String, dynamic>;
                  final mood = data['mood'] as String?;
                  spots.add(FlSpot(i.toDouble(), moodToValue(mood).toDouble()));
                }

                // Get latest journal sentiment
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('journals')
                      .where('userId', isEqualTo: user.uid)
                      .orderBy('date', descending: true)
                      .limit(10)
                      .get(),
                  builder: (context, journalSnapshot) {
                    double journalSentiment = 0.5; // neutral default

                    if (journalSnapshot.hasData) {
                      final journals = journalSnapshot.data!.docs
                          .map((doc) => JournalEntry.fromMap(
                              doc.data() as Map<String, dynamic>, doc.id))
                          .toList();
                      journalSentiment = _calculateAverageSentiment(journals);
                    }

                    final lineColor = theme.colorScheme.primary;
                    final sentimentColor = Color.lerp(
                      Colors.red,
                      Colors.green,
                      journalSentiment,
                    )!;

                    return Column(
                      children: [
                        // Mood line chart
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: (moodList.length - 1).toDouble(),
                              minY: 0.5,
                              maxY: 6.5,
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= moodList.length) {
                                        return const Text('');
                                      }
                                      return Text(
                                        '${idx + 1}',
                                        style: theme.textTheme.labelSmall,
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const labels = [
                                        '',
                                        '😢',
                                        '😰',
                                        '😠',
                                        '😐',
                                        '😌',
                                        '😊'
                                      ];
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= labels.length) {
                                        return const Text('');
                                      }
                                      return Text(
                                        labels[idx],
                                        style: theme.textTheme.labelSmall,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: lineColor,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: lineColor.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: cardPadding),
                        // Journal Sentiment Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(cardPadding * 0.8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                sentimentColor.withValues(alpha: 0.1),
                                sentimentColor.withValues(alpha: 0.05),
                              ],
                            ),
                            border: Border.all(
                              color: sentimentColor.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    journalSentiment > 0.6
                                        ? Icons.sentiment_very_satisfied
                                        : journalSentiment > 0.4
                                            ? Icons.sentiment_satisfied
                                            : Icons.sentiment_dissatisfied,
                                    color: sentimentColor,
                                    size: ResponsiveUtils.getIconSize(context) *
                                        0.7,
                                  ),
                                  SizedBox(width: cardPadding * 0.5),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Journal Sentiment',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: sentimentColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: cardPadding * 0.25),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            minHeight: 8,
                                            value: journalSentiment,
                                            backgroundColor: Colors.grey
                                                .withValues(alpha: 0.2),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              sentimentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: cardPadding * 0.5),
                                  Text(
                                    '${(journalSentiment * 100).toStringAsFixed(0)}%',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: sentimentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: cardPadding * 0.5),
                              Text(
                                journalSentiment > 0.6
                                    ? 'Very Positive - Great journal entries!'
                                    : journalSentiment > 0.4
                                        ? 'Neutral - Mixed sentiments in entries'
                                        : 'Needs Support - Consider self-care',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: sentimentColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCompletionChart(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Text('Sign in to view task stats');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Text('Error loading tasks: ${snapshot.error}');
        }
        final docs = snapshot.data?.docs ?? [];
        int completed = 0;
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          if (data['isCompleted'] == true) completed++;
        }
        final total = docs.length;
        final remaining = total - completed;
        final completionPct = total == 0 ? 0.0 : (completed / total) * 100;
        final theme = Theme.of(context);
        final completedColor = theme.colorScheme.primary;
        final remainingColor =
            theme.colorScheme.secondary.withValues(alpha: 0.3);

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.18),
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                ],
              ),
            ),
            padding: EdgeInsets.all(ResponsiveUtils.getCardPadding(context)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = ResponsiveUtils.isMobile(context);
                final isTablet = ResponsiveUtils.isTablet(context);
                final pieSize = isMobile
                    ? (constraints.maxWidth * 0.35).clamp(100.0, 130.0)
                    : isTablet
                        ? (constraints.maxWidth * 0.32).clamp(120.0, 160.0)
                        : (constraints.maxWidth * 0.3).clamp(140.0, 180.0);
                final outerRadius = pieSize * 0.5;
                final holeRadius = outerRadius * 0.72;
                final pctStr = completionPct.toStringAsFixed(0);
                final chartSpacing =
                    ResponsiveUtils.getCardPadding(context) * 1.2;

                if (isMobile) {
                  return Column(
                    children: [
                      SizedBox(
                        width: pieSize,
                        height: pieSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: holeRadius,
                                startDegreeOffset: -90,
                                sections: [
                                  PieChartSectionData(
                                    color: remainingColor,
                                    value: remaining <= 0
                                        ? 0.0001
                                        : remaining.toDouble(),
                                    title: '',
                                    radius: outerRadius,
                                  ),
                                  if (completed > 0)
                                    PieChartSectionData(
                                      color: completedColor,
                                      value: completed.toDouble(),
                                      title: '',
                                      radius: outerRadius,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$pctStr%',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Done',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: chartSpacing),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 18, color: completedColor),
                              const SizedBox(width: 6),
                              Text('Tasks', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _legendEntry(
                            color: completedColor,
                            label: 'Completed',
                            value:
                                '$completed • ${completionPct.toStringAsFixed(0)}%',
                            emphasize: true,
                          ),
                          const SizedBox(height: 6),
                          _legendEntry(
                            color: remainingColor,
                            label: 'Remaining',
                            value:
                                '$remaining • ${(100 - completionPct).toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: total == 0 ? 0 : completed / total,
                              backgroundColor:
                                  remainingColor.withValues(alpha: 0.3),
                              valueColor:
                                  AlwaysStoppedAnimation(completedColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completed of $total completed',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: pieSize,
                      height: pieSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: holeRadius,
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  color: remainingColor,
                                  value: remaining <= 0
                                      ? 0.0001
                                      : remaining.toDouble(),
                                  title: '',
                                  radius: outerRadius,
                                ),
                                if (completed > 0)
                                  PieChartSectionData(
                                    color: completedColor,
                                    value: completed.toDouble(),
                                    title: '',
                                    radius: outerRadius,
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$pctStr%',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Done',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 45),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 18, color: completedColor),
                              const SizedBox(width: 6),
                              Text('Tasks', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _legendEntry(
                            color: completedColor,
                            label: 'Completed',
                            value:
                                '$completed • ${completionPct.toStringAsFixed(0)}%',
                            emphasize: true,
                          ),
                          const SizedBox(height: 6),
                          _legendEntry(
                            color: remainingColor,
                            label: 'Remaining',
                            value:
                                '$remaining • ${(100 - completionPct).toStringAsFixed(0)}%',
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 10,
                              value: total == 0 ? 0 : completed / total,
                              backgroundColor:
                                  remainingColor.withValues(alpha: 0.3),
                              valueColor:
                                  AlwaysStoppedAnimation(completedColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completed of $total completed',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _legendEntry({
    required Color color,
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: emphasize ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: emphasize ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
