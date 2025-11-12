// Clean, unified dashboard screen with mood check-in integration.

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/focus_service.dart';
import '../models/focus_session.dart';
import '../services/focus_timer_manager.dart';
import '../services/mood_service.dart';
import 'package:provider/provider.dart';
import '../models/mood_check_in.dart';
import '../theme/app_theme.dart';
import '../widgets/mood_check_in_dialog.dart';

import 'journal_screen.dart';
import 'task_list_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'pomodoro_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final TaskService _taskService = TaskService();
  final FocusService _focusService = FocusService();
  // (Legacy) Previously instantiated MoodService here; now resolved globally via Provider in main.dart.
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreenContent(
        taskService: _taskService,
        focusService: _focusService,
      ),
      const JournalScreen(),
      TaskListScreen(taskService: _taskService),
      const ProfileScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded), label: 'Journal'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded), label: 'Profile'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.unselectedWidgetColor,
            backgroundColor: theme.colorScheme.surface,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: false,
            onTap: _onItemTapped,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  final TaskService taskService;
  final FocusService focusService;
  const HomeScreenContent({
    super.key,
    required this.taskService,
    required this.focusService,
  });

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  static bool _midnightScheduled = false;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMidnightResetOnce();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showMoodCheckInIfNeeded());
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  void _scheduleMidnightResetOnce() {
    if (_midnightScheduled) return;
    _midnightScheduled = true;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    _midnightTimer = Timer(diff, () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await widget.focusService.setLastResetDate(user.uid, DateTime.now());
      }
      if (mounted) setState(() {});
      _midnightScheduled = false; // allow re-schedule
      _scheduleMidnightResetOnce();
    });
  }

  Future<void> _showMoodCheckInIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey =
          'mood_dismissed_${today.year}_${today.month}_${today.day}';
      final wasDismissedToday = prefs.getBool(todayKey) ?? false;

      if (wasDismissedToday) return; // User dismissed it today

      final buildContext = context;
      final svc = buildContext.read<MoodService>();
      final hasMood = await svc.hasMoodToday(user.uid);

      if (!mounted) return;
      if (!hasMood) {
        // Show mood check-in dialog with delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showMoodCheckInDialog(
              buildContext,
              onDismissed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(todayKey, true);
              },
              onCompleted: () {
                // Mood logged successfully
                debugPrint('Mood check-in completed');
              },
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Mood preload failed: $e');
    }
  }

  void _showMoodSelectionDialog() {
    showMoodCheckInDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _greetingForNow();
    final name = user?.displayName?.split(' ').first ?? 'There';
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, $name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    )),
                const SizedBox(height: 4),
                Text('Stay focused and achieve your goals',
                    style: TextStyle(
                        fontSize: 14,
                        color: onSurface.withValues(alpha: 0.65))),
              ],
            ),
            const SizedBox(height: 24),
            _buildMoodSummaryCard(context),
            const SizedBox(height: 28),
            StreamBuilder<List<Task>>(
              stream: widget.taskService.getTasks(),
              builder: (context, snapshot) {
                final allTasks = snapshot.data ?? [];
                final now = DateTime.now();
                final todayMidnight = DateTime(now.year, now.month, now.day);
                final tomorrowMidnight =
                    todayMidnight.add(const Duration(days: 1));
                final tasksDueToday = allTasks
                    .where((t) =>
                        !t.isCompleted &&
                        t.deadline.isAfter(todayMidnight) &&
                        t.deadline.isBefore(tomorrowMidnight))
                    .length;
                final completedTasks =
                    allTasks.where((t) => t.isCompleted).length;
                final overdueTasks = allTasks
                    .where((t) => !t.isCompleted && t.deadline.isBefore(now))
                    .length;
                return GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildOverviewCard(
                      context,
                      title: 'Tasks Due Today',
                      value: tasksDueToday.toString(),
                      color: softBlue,
                      icon: Icons.access_time_filled_rounded,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TaskListScreen(
                                  taskService: widget.taskService))),
                    ),
                    _buildOverviewCard(
                      context,
                      title: 'Completed Tasks',
                      value: completedTasks.toString(),
                      color: mintGreen,
                      icon: Icons.check_circle_rounded,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TaskListScreen(
                                  taskService: widget.taskService,
                                  initialFilter:
                                      TaskCompletionFilter.completed))),
                    ),
                    _buildOverviewCard(
                      context,
                      title: 'Overdue Tasks',
                      value: overdueTasks.toString(),
                      color: const Color.fromARGB(255, 208, 79, 79),
                      icon: Icons.warning_rounded,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TaskListScreen(
                                  taskService: widget.taskService,
                                  initialFilter:
                                      TaskCompletionFilter.overdue))),
                    ),
                    _buildStudyTimeCard(context),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            _buildSmartTaskSuggestions(context, user),
          ],
        ),
      ),
    );
  }

  String _greetingForNow() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good Morning';
    if (h >= 12 && h < 17) return 'Good Afternoon';
    if (h >= 17 && h < 22) return 'Good Evening';
    return 'Good Night'; // Covers 22:00-04:59 (10 PM to 4:59 AM)
  }

  Widget _buildSmartTaskSuggestions(BuildContext context, User? user) {
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return StreamBuilder<MoodCheckIn?>(
      stream: context.read<MoodService>().latestMoodToday(user.uid),
      builder: (context, moodSnapshot) {
        final currentMood = moodSnapshot.data?.mood;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Smart Task Suggestions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (currentMood != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Based on mood',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Task>>(
              stream: widget.taskService.getSmartPrioritizedTasks(currentMood),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = taskSnapshot.data ?? [];
                final incompleteTasks =
                    tasks.where((t) => !t.isCompleted).take(3).toList();

                if (incompleteTasks.isEmpty) {
                  return Text(
                    'No pending tasks. Great job! 🎉',
                    style: TextStyle(
                      fontSize: 16,
                      color: onSurface.withOpacity(0.6),
                    ),
                  );
                }

                return Column(
                  children: incompleteTasks
                      .map((task) => _buildSmartTaskCard(context, task))
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmartTaskCard(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isOverdue = task.deadline.isBefore(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red : _getPriorityColor(task.priority),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            task.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                _getEnergyIcon(task.requiredEnergy),
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${task.requiredEnergy.name} energy • ${task.category.name}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskListScreen(
                  taskService: widget.taskService,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return softBlue;
    }
  }

  IconData _getEnergyIcon(TaskEnergyLevel energy) {
    switch (energy) {
      case TaskEnergyLevel.high:
        return Icons.flash_on;
      case TaskEnergyLevel.medium:
        return Icons.remove;
      case TaskEnergyLevel.low:
        return Icons.battery_2_bar;
    }
  }

  Widget _buildMoodSummaryCard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return StreamBuilder<MoodCheckIn?>(
      stream: context.read<MoodService>().latestMoodToday(user.uid),
      builder: (context, snapshot) {
        String emoji = '🤔';
        String headline = 'How are you feeling?';
        String subtitle = 'Tap to log today\'s mood';
        if (snapshot.hasData && snapshot.data != null) {
          final entry = snapshot.data!;
          final mood = entry.mood.toLowerCase();
          switch (mood) {
            case 'happy':
              emoji = '😊';
              break;
            case 'neutral':
              emoji = '😐';
              break;
            case 'sad':
              emoji = '😔';
              break;
            case 'angry':
              emoji = '😠';
              break;
            case 'stressed':
              emoji = '😩';
              break;
            case 'calm':
              emoji = '🧘';
              break;
          }
          headline = 'Feeling ${entry.mood}';
          subtitle = 'Keep up the great work!';
        }
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showMoodSelectionDialog,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    softBlue.withValues(alpha: 0.8),
                    mintGreen.withValues(alpha: 0.9)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            )),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: onSurface.withValues(alpha: 0.75),
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_rounded,
                      color: onSurface.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(BuildContext context,
      {required String title,
      required String value,
      required Color color,
      required IconData icon,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 30),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(value,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ],
              ),
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: onSurface.withValues(alpha: 0.85))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyTimeCard(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildOverviewCard(context,
          title: 'Study Time',
          value: '-/-',
          color: softBlue,
          icon: Icons.bar_chart_rounded);
    }
    return StreamBuilder<UserFocusPrefs>(
      stream: widget.focusService.focusPrefsStream(user.uid),
      builder: (context, prefsSnap) {
        final prefs = prefsSnap.data;
        final goalMin = prefs?.dailyGoalMinutes ?? 240;
        return StreamBuilder<List<FocusSession>>(
          stream: widget.focusService.sessionsForDay(user.uid, DateTime.now()),
          builder: (context, sessSnap) {
            final sessions = sessSnap.data ?? const [];
            final persistedMinutes =
                sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
            final manager = FocusTimerManager();
            return AnimatedBuilder(
              animation: manager,
              builder: (context, _) {
                final localAgg = manager.savedCurrentBlockMinutes;
                final displayedMinutes =
                    localAgg > persistedMinutes ? localAgg : persistedMinutes;
                final totalHrs = displayedMinutes / 60;
                final goalHrs = goalMin / 60;
                final value =
                    '${totalHrs.toStringAsFixed(1)}/${goalHrs.toStringAsFixed(0)} Hrs';
                final savedLine = '$displayedMinutes min saved';
                final lastSync = manager.lastSync;
                final syncLine = lastSync != null
                    ? 'Synced ${TimeOfDay.fromDateTime(lastSync).format(context)}'
                    : null;
                return InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PomodoroScreen(
                              focusService: widget.focusService))),
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: theme.colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.bar_chart_rounded,
                                  color: softBlue.withValues(alpha: 0.7),
                                  size: 30),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: softBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(value,
                                    style: TextStyle(
                                        color: softBlue.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                          Text('Study Time',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface.withValues(alpha: 0.85))),
                          const SizedBox(height: 4),
                          Text(savedLine,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: onSurface.withValues(alpha: 0.7))),
                          if (syncLine != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(syncLine,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          onSurface.withValues(alpha: 0.45))),
                            ),
                          LinearProgressIndicator(
                            value: goalMin == 0
                                ? 0
                                : (displayedMinutes / goalMin).clamp(0, 1),
                            backgroundColor: onSurface.withValues(alpha: 0.1),
                            color: softBlue,
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
