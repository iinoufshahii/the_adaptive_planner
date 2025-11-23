/// Clean, unified dashboard screen with mood check-in integration.
/// Provides main navigation hub with bottom/side navigation for mobile/web layouts.
/// Manages 5 main screens: Home, Journal, Tasks, Analytics, Settings.
library;

import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/focus_session.dart';
import '../models/mood_check_in.dart';
import '../models/task.dart';
import '../Service/focus_service.dart';
import '../Service/focus_timer_manager.dart';
import '../Service/mood_service.dart';
import '../Service/task_service.dart';
import '../Theme/App_Theme.dart';
import '../Widgets/Responsive_widget.dart';
import '../dialogs/mood_check_in_dialog.dart';
import '../dialogs/app_dialogs.dart';
import 'analytics_screen.dart';
import 'journal_screen.dart';
import 'pomodoro_screen.dart';
import 'settings_screen.dart';
import 'task_list_screen.dart';

/// Main dashboard StatefulWidget managing app navigation and screen lifecycle.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// State for dashboard managing selected nav index, services, and screen list.
class _DashboardScreenState extends State<DashboardScreen> {
  /// Currently selected navigation index (0=Home, 1=Journal, 2=Tasks, 3=Analytics, 4=Settings)
  int _selectedIndex = 0;

  /// Service for managing task CRUD operations via Firestore
  final TaskService _taskService = TaskService();

  /// Service for managing focus sessions and pomodoro timer state
  final FocusService _focusService = FocusService();
  // Note: MoodService is now provided globally via Provider in main.dart, not instantiated here
  /// List of screen widgets corresponding to each nav index
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize list of screen widgets for each navigation destination
    _screens = [
      // Index 0: Home dashboard with quick stats and mood integration
      HomeScreenContent(
        taskService: _taskService,
        focusService: _focusService,
      ),
      // Index 1: Journal entries management screen
      const JournalScreen(),
      // Index 2: Task list with filtering and management
      TaskListScreen(taskService: _taskService),
      // Index 3: Analytics and productivity patterns
      const AnalyticsScreen(),
      // Index 4: Settings and user preferences
      const SettingsScreen(),
    ];
  }

  /// Callback: Update selected navigation index and rebuild UI
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isWebView = ResponsiveUtils.isWeb(context);

    if (isWebView) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              backgroundColor: theme.colorScheme.surface,
              selectedIconTheme: IconThemeData(
                color: theme.colorScheme.primary,
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: theme.unselectedWidgetColor,
                size: 24,
              ),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: theme.unselectedWidgetColor,
                fontSize: 12,
              ),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_rounded),
                  label: Text('Journal'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.task_alt_rounded),
                  label: Text('Tasks'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_rounded),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _screens[_selectedIndex],
      bottomNavigationBar: ResponsiveUtils.isWeb(context)
          ? null
          : ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: getGlassNavBarDecoration(
                      context, theme.brightness == Brightness.dark),
                  child: BottomNavigationBar(
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.home_rounded), label: 'Home'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book_rounded),
                          label: 'Journal'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.task_alt_rounded), label: 'Tasks'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.analytics_rounded),
                          label: 'Analytics'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.settings_rounded),
                          label: 'Settings'),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: theme.colorScheme.primary,
                    unselectedItemColor: theme.unselectedWidgetColor,
                    backgroundColor: Colors.transparent,
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: ResponsiveUtils.isTablet(context),
                    onTap: _onItemTapped,
                    elevation: 0,
                  ),
                ),
              ),
            ),
    );
  }
}

/// StatefulWidget displaying home screen with task stats, study time, and mood tracking.
/// Shows greeting, mood summary card, daily task overview (due/completed/overdue), and smart task suggestions.
class HomeScreenContent extends StatefulWidget {
  /// Service for task CRUD operations and smart task filtering
  final TaskService taskService;

  /// Service for focus session management and study time tracking
  final FocusService focusService;

  const HomeScreenContent({
    super.key,
    required this.taskService,
    required this.focusService,
  });

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

/// State managing midnight reset scheduling and mood check-in prompt logic.
class _HomeScreenContentState extends State<HomeScreenContent> {
  /// Static flag: prevents multiple midnight reset timers from being scheduled
  static bool _midnightScheduled = false;

  /// Timer reference for midnight reset - allows cleanup on dispose
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    // Schedule daily reset at midnight to reset focus session streak
    _scheduleMidnightResetOnce();
    // Queue mood check-in prompt after frame renders to ensure UI is ready
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showMoodCheckInIfNeeded());
  }

  @override
  void dispose() {
    // Clean up timer to prevent memory leaks and multiple timers running
    _midnightTimer?.cancel();
    super.dispose();
  }

  /// Schedule daily reset at midnight to clear focus session state.
  /// Uses static flag to ensure only one timer runs at a time.
  /// Reschedules itself recursively each day.
  void _scheduleMidnightResetOnce() {
    // Guard: prevent multiple timers if called multiple times
    if (_midnightScheduled) return;
    _midnightScheduled = true;

    final now = DateTime.now();
    // Calculate tomorrow midnight (start of next day)
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    // Calculate time remaining until midnight
    final diff = tomorrow.difference(now);

    // Create timer that fires at midnight
    _midnightTimer = Timer(diff, () async {
      final user = FirebaseAuth.instance.currentUser;
      // Conditional: only save reset if user is authenticated
      if (user != null) {
        // Persist reset date to Firestore for focus streak tracking
        await widget.focusService.setLastResetDate(user.uid, DateTime.now());
      }
      // Rebuild UI if widget still mounted after async operation
      if (mounted) setState(() {});
      // Reset flag and reschedule for next day
      _midnightScheduled = false;
      _scheduleMidnightResetOnce();
    });
  }

  /// Check if user needs to log mood today, show dialog if not yet completed.
  /// Uses SharedPreferences to track if user dismissed mood check-in today.
  Future<void> _showMoodCheckInIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    // Guard: exit if no user or widget not mounted
    if (user == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      // Generate unique key for today's mood dismissal (format: mood_dismissed_YYYY_M_D)
      final todayKey =
          'mood_dismissed_${today.year}_${today.month}_${today.day}';
      // Check if user already dismissed today's mood check-in
      final wasDismissedToday = prefs.getBool(todayKey) ?? false;

      // Conditional: skip if already dismissed today
      if (wasDismissedToday) return;

      // Get MoodService from Provider for mood queries
      final svc = context.read<MoodService>();
      // Check if user already logged mood today in Firestore
      final hasMood = await svc.hasMoodToday(user.uid);

      // Safety check: widget may have been disposed during async operation
      if (!mounted) return;

      // Conditional: show dialog only if no mood logged yet
      if (!hasMood) {
        // Delay dialog to ensure dashboard is fully rendered before showing modal.
        // New users after signup need extra time for all widgets to build.
        Future.delayed(const Duration(milliseconds: 1500), () {
          // Double-check widget still mounted after delay
          if (mounted) {
            showMoodCheckInDialog(
              context,
              // Callback: save dismissal flag when user skips mood check-in
              onDismissed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(todayKey, true);
              },
              // Callback: log success when mood check-in completed using reusable system
              onCompleted: () {
                debugPrint('Mood check-in completed');
                showFloatingBottomDialog(
                  context,
                  message: 'Mood logged successfully! 😊',
                  type: AppMessageType.success,
                );
              },
            );
          }
        });
      }
    } catch (e) {
      // Error handling: show user-friendly error message using reusable dialog system
      debugPrint('Mood preload failed: $e');
      if (mounted) {
        showAutoDismissDialog(
          context,
          title: 'Mood Check-In Error',
          message: 'Failed to load mood check-in. Please try again.',
          type: AppMessageType.error,
        );
      }
    }
  }

  /// Show mood check-in dialog on demand when user taps mood summary card.
  void _showMoodSelectionDialog() {
    showMoodCheckInDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Generate time-based greeting (Morning/Afternoon/Evening/Night)
    final greeting = _greetingForNow();
    // Extract first name from user display name, fallback to "There"
    final name = user?.displayName?.split(' ').first ?? 'There';
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return SafeArea(
      child: Center(
        // Constrain max width for web layout (1200px), fill for mobile
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.isWeb(context) ? 1200 : double.infinity,
          ),
          // ScrollView: prevent overflow on small screens
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveUtils.getDefaultPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting header with time-based message
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting, $name',
                        style: TextStyle(
                          fontSize:
                              ResponsiveUtils.getGreetingFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        )),
                    const SizedBox(height: 4),
                    // Tagline subtitle
                    Text('Stay focused and achieve your goals',
                        style: TextStyle(
                            fontSize:
                                ResponsiveUtils.getSubtitleFontSize(context),
                            color: onSurface.withValues(alpha: 0.65))),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getDefaultPadding(context)),

                // Mood summary card with emoji and mood status
                _buildMoodSummaryCard(context),
                SizedBox(
                    height: ResponsiveUtils.getDefaultPadding(context) + 8),

                // Task overview cards grid (StreamBuilder for real-time data)
                StreamBuilder<List<Task>>(
                  stream: widget.taskService.getTasks(),
                  builder: (context, snapshot) {
                    // Error handling: show error message if stream fails
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(height: 16),
                            Text('Failed to load tasks',
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Loading state: show spinner while fetching
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allTasks = snapshot.data ?? [];
                    final now = DateTime.now();
                    // Calculate today's date range boundaries
                    final todayMidnight =
                        DateTime(now.year, now.month, now.day);
                    final tomorrowMidnight =
                        todayMidnight.add(const Duration(days: 1));

                    // Count tasks due today (not completed, deadline between midnight boundaries)
                    final tasksDueToday = allTasks
                        .where((t) =>
                            !t.isCompleted &&
                            !t.deadline.isBefore(todayMidnight) &&
                            t.deadline.isBefore(tomorrowMidnight))
                        .length;

                    // Count completed tasks (for progress indication)
                    final completedTasks =
                        allTasks.where((t) => t.isCompleted).length;

                    // Count overdue tasks (incomplete tasks with deadline before now)
                    final overdueTasks = allTasks
                        .where(
                            (t) => !t.isCompleted && t.deadline.isBefore(now))
                        .length;

                    // Responsive grid: 2 cols mobile, 3+ cols tablet/web
                    return GridView.count(
                      physics:
                          const NeverScrollableScrollPhysics(), // Prevent nested scroll
                      shrinkWrap: true, // Size to children, not full viewport
                      crossAxisCount:
                          ResponsiveUtils.getGridCrossAxisCount(context),
                      crossAxisSpacing:
                          ResponsiveUtils.getDefaultPadding(context),
                      mainAxisSpacing:
                          ResponsiveUtils.getDefaultPadding(context),
                      childAspectRatio: ResponsiveUtils.isMobile(context)
                          ? 1.0
                          : ResponsiveUtils.isTablet(context)
                              ? 1.1
                              : 1.2,
                      children: [
                        // Card 1: Tasks due today (clickable -> TaskListScreen)
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
                                      taskService: widget.taskService,
                                      initialFilter:
                                          TaskCompletionFilter.DueToday))),
                        ),

                        // Card 2: Completed tasks (clickable -> TaskListScreen with completed filter)
                        _buildOverviewCard(
                          context,
                          title: 'Completed Tasks',
                          value: completedTasks.toString(),
                          color: const Color.fromARGB(255, 61, 158, 40),
                          icon: Icons.check_circle_rounded,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TaskListScreen(
                                      taskService: widget.taskService,
                                      initialFilter:
                                          TaskCompletionFilter.Completed))),
                        ),

                        // Card 3: Overdue tasks (warning indicator, clickable -> filtered TaskListScreen)
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
                                          TaskCompletionFilter.Overdue))),
                        ),

                        // Card 4: Study time tracking (shows current session progress + daily goal)
                        _buildStudyTimeCard(context),
                      ],
                    );
                  },
                ),
                SizedBox(height: ResponsiveUtils.getDefaultPadding(context)),

                // Smart task suggestions section (AI-powered by mood/energy)
                _buildSmartTaskSuggestions(context, user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Return time-of-day greeting based on current hour.
  /// Used for personalized user welcome message.
  String _greetingForNow() {
    final h = DateTime.now().hour;
    // Conditional: return greeting based on hour ranges
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
        final currentEnergyLevel = moodSnapshot.data?.energyLevel;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Smart Task Suggestions',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getTitleFontSize(context),
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (currentMood != null || currentEnergyLevel != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      currentMood != null && currentEnergyLevel != null
                          ? 'AI powered'
                          : currentMood != null
                              ? 'Based on mood'
                              : 'Based on energy',
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
              stream: widget.taskService
                  .getSmartPrioritizedTasks(currentMood, currentEnergyLevel),
              builder: (context, taskSnapshot) {
                // Error handling: show error message if stream fails
                if (taskSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_outlined,
                              size: 32,
                              color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 8),
                          Text('Unable to load task suggestions',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }

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
                      color: onSurface.withValues(alpha: 0.6),
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
    final iconSize = ResponsiveUtils.isMobile(context) ? 14.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.getDefaultPadding(context) * 0.6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getCardPadding(context) * 0.75),
        ),
        color: theme.cardTheme.color,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getCardPadding(context),
            vertical: ResponsiveUtils.isMobile(context) ? 8 : 12,
          ),
          leading: Container(
            width: ResponsiveUtils.isMobile(context) ? 12 : 16,
            height: ResponsiveUtils.isMobile(context) ? 12 : 16,
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red : _getPriorityColor(task.priority),
              shape: BoxShape.circle,
            ),
          ),
          title: Text(
            task.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtils.getBodyFontSize(context),
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                _getEnergyIcon(task.requiredEnergy),
                size: iconSize,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${task.requiredEnergy.name} energy • ${task.category}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: ResponsiveUtils.getSmallFontSize(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: iconSize,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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

  /// Displays current user's mood check-in with glassmorphic card design.
  /// Shows emoji representation of latest mood logged today.
  /// Tapping the card opens mood selection dialog to update mood.
  /// Returns empty SizedBox if user not authenticated.
  Widget _buildMoodSummaryCard(BuildContext context) {
    // Get current user from Firebase Auth (may be null if not logged in)
    final user = FirebaseAuth.instance.currentUser;
    // Guard: Return empty widget if user is not authenticated
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // StreamBuilder: Listen to latest mood check-in for current user
    // Updates widget whenever user logs a new mood today
    return StreamBuilder<MoodCheckIn?>(
      stream: context.read<MoodService>().latestMoodToday(user.uid),
      builder: (context, snapshot) {
        // Initialize defaults: thinking face emoji, generic prompt
        String emoji = '🤔';
        String headline = 'How are you feeling?';
        String subtitle = 'Tap to log today\'s mood';

        // Conditional: If mood data exists, map mood text to emoji and update headline
        if (snapshot.hasData && snapshot.data != null) {
          final entry = snapshot.data!;
          final mood = entry.mood.toLowerCase();

          // Switch statement: Maps mood string to corresponding emoji
          // Use case: Display visually appropriate emoji for user's current mood
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
          // Update headline to show current mood
          headline = 'Feeling ${entry.mood}';
        }
        // InkWell: Makes card tappable for mood selection dialog
        // TapCallback: Open mood selection dialog on tap
        return InkWell(
          borderRadius:
              BorderRadius.circular(ResponsiveUtils.getCardPadding(context)),
          onTap: _showMoodSelectionDialog,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(ResponsiveUtils.getCardPadding(context)),
            // BackdropFilter: Apply 15px blur creating glassmorphic frosted glass effect
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              // Container: Main card body with gradient and shadows
              child: Container(
                padding:
                    EdgeInsets.all(ResponsiveUtils.getCardPadding(context)),
                // BoxDecoration: Glassmorphic styling with gradient, border, and shadow layers
                decoration: BoxDecoration(
                  // LinearGradient: Diagonal blue gradient with decreasing opacity (top-left to bottom-right)
                  // Creates subtle depth effect: bright blue top-left, fading to light cyan bottom-right
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF68D9FF)
                          .withValues(alpha: 0.8), // Bright cyan (80%)
                      const Color.fromARGB(255, 141, 222, 249)
                          .withValues(alpha: 0.6), // Medium cyan (60%)
                      const Color.fromARGB(255, 200, 243, 255)
                          .withValues(alpha: 0.4), // Light cyan (40%)
                    ],
                    stops: const [
                      0.0,
                      0.5,
                      1.0
                    ], // Evenly distributed color stops
                  ),
                  borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getCardPadding(context)),
                  // White border with 60% opacity for glass frame effect
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255)
                        .withValues(alpha: 0.6),
                    width: 3,
                  ),
                  // Multiple box shadows: Create layered 3D depth effect
                  boxShadow: [
                    // Deep shadow (layer 1): Bottom dark shadow for primary depth
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 157, 255)
                          .withValues(alpha: 0.15), // Blue-tinted shadow
                      blurRadius: 5,
                      offset: const Offset(0, 12), // Downward offset
                      spreadRadius: 2, // Shadow spreads 2px
                    ),
                    // Medium shadow (layer 2): Closer shadow for subtle depth
                    BoxShadow(
                      color: const Color.fromARGB(255, 28, 191, 255)
                          .withValues(alpha: 0.1),
                      blurRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    // Subtle inner shadow (layer 3): Top-left inner glow for glass effect
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, -2), // Upward offset
                      spreadRadius: -1,
                    ),
                    // Highlight shadow (layer 4): Top-left light glow for shine effect
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(-3, -3), // Top-left diagonal
                      spreadRadius: -2,
                    ),
                  ],
                ),
                // Row: Horizontal layout with mood emoji on left, text on right
                child: Row(
                  children: [
                    // Mood emoji: Large display (40-56px depending on device)
                    Text(
                      emoji,
                      style: TextStyle(
                        // Responsive sizing: Larger for web/tablet, smaller for mobile
                        fontSize: ResponsiveUtils.isWeb(context)
                            ? 56
                            : ResponsiveUtils.isTablet(context)
                                ? 48
                                : 40,
                      ),
                    ),
                    // Horizontal spacer: Separate emoji from text
                    SizedBox(
                        width:
                            ResponsiveUtils.getDefaultPadding(context) * 0.75),
                    // Expanded: Text column fills remaining horizontal space
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Headline text: Shows mood status or prompt
                          // Responsive font size based on device type
                          Text(
                            headline,
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtils.getTitleFontSize(context),
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle text: Instruction or timestamp info
                          // 75% opacity for subtle appearance
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtils.getBodyFontSize(context),
                              color: onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Edit icon: Visual indicator that card is tappable/editable
                    Icon(
                      Icons.edit_rounded,
                      color: onSurface.withValues(alpha: 0.6),
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

  /// Builds metric card widget for task overview statistics.
  /// Displays title, value, icon, and optional tap callback for navigation.
  /// Parameters:
  ///   - title: Card heading (e.g., "Tasks Due Today")
  ///   - value: Primary metric display (numeric string)
  ///   - color: Icon and value background color for visual categorization
  ///   - icon: Material icon displayed in top-left
  ///   - onTap: Optional callback for card tap (enables navigation)
  Widget _buildOverviewCard(BuildContext context,
      {required String title,
      required String value,
      required Color color,
      required IconData icon,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    // InkWell: Makes card tappable with ripple effect
    // TapCallback: Navigate to filtered task list or execute onTap callback
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      // Card: Material elevated container with shadow
      child: Card(
        elevation: 4, // Provides depth/shadow appearance
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ResponsiveUtils.getCardPadding(context))),
        color: theme.cardTheme.color,
        // Padding: Inner spacing from card edge to content
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getCardPadding(context)),
          // Column: Vertical layout with icon/value row at top, title at bottom
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Icon on left, metric badge on right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon: Color-coded indicator of metric category
                  Icon(icon,
                      color: color, size: ResponsiveUtils.getIconSize(context)),
                  // Container: Badge showing numeric value with colored background
                  // Use case: Eye-catching display of key metric number
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    // Decoration: Light background of category color (15% opacity)
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15), // Subtle background
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Value text: Bold numeric string in color-matched font
                    child: Text(value,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize:
                                ResponsiveUtils.getSmallFontSize(context))),
                  ),
                ],
              ),
              // Title text: Card heading (Tasks Due Today, Completed, etc.)
              // 85% opacity for secondary prominence vs. value
              Text(title,
                  style: TextStyle(
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                      fontWeight: FontWeight.w500,
                      color: onSurface.withValues(alpha: 0.85))),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds study time tracking card showing daily progress vs. goal.
  /// Combines Firestore persisted focus sessions with real-time timer state.
  /// Streams both user preferences (daily goal) and current sessions.
  /// Displays hours studied / hours goal with animated progress bar.
  Widget _buildStudyTimeCard(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final user = FirebaseAuth.instance.currentUser;

    // Guard: Return placeholder if user not authenticated
    if (user == null) {
      return _buildOverviewCard(context,
          title: 'Study Time',
          value: '-/-',
          color: softBlue,
          icon: Icons.bar_chart_rounded);
    }

    // StreamBuilder 1: Listen to user's daily study goal preference
    // Re-builds when user updates their daily goal (e.g., 240 minutes default)
    return StreamBuilder<UserFocusPrefs>(
      stream: widget.focusService.focusPrefsStream(user.uid),
      builder: (context, prefsSnap) {
        final prefs = prefsSnap.data;
        // Extract daily goal in minutes (default 240 = 4 hours if not set)
        final goalMin = prefs?.dailyGoalMinutes ?? 240;

        // StreamBuilder 2: Listen to focus sessions for today
        // Fetches all completed focus blocks for current date
        return StreamBuilder<List<FocusSession>>(
          stream: widget.focusService.sessionsForDay(user.uid, DateTime.now()),
          builder: (context, sessSnap) {
            final sessions = sessSnap.data ?? const [];

            // fold() loop: Accumulate total duration from all sessions
            // Purpose: Sum durationMinutes across all focus sessions today
            // Logic: Start with 0, add each session's duration minutes
            final persistedMinutes =
                sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

            // FocusTimerManager: Access real-time Pomodoro timer state (if running)
            // Use case: Get current running session minutes before they're persisted
            final manager = FocusTimerManager();

            // AnimatedBuilder: Rebuild when FocusTimerManager changes (real-time timer tick)
            // Purpose: Display live timer updates without waiting for Firestore sync
            return AnimatedBuilder(
              animation: manager,
              builder: (context, _) {
                // Get current session minutes still in progress (not yet saved)
                final localAgg = manager.savedCurrentBlockMinutes;

                // Conditional: Use larger value (avoids showing less time after timer pause)
                // Logic: If active timer has more minutes, show that; otherwise show persisted
                final displayedMinutes =
                    localAgg > persistedMinutes ? localAgg : persistedMinutes;

                // Convert minutes to hours for display (e.g., 120 minutes = 2.0 hours)
                final totalHrs = displayedMinutes / 60;
                final goalHrs = goalMin / 60;

                // Format display value: "2.5/4 Hrs" (current/goal)
                final value =
                    '${totalHrs.toStringAsFixed(1)}/${goalHrs.toStringAsFixed(0)} Hrs';

                // Secondary info: Show minutes saved (persisted to database)
                final savedLine = '$displayedMinutes min saved';

                // Tertiary info: Show last sync time (e.g., "Synced 3:45 PM")
                final lastSync = manager.lastSync;
                final syncLine = lastSync != null
                    ? 'Synced ${TimeOfDay.fromDateTime(lastSync).format(context)}'
                    : null;

                // InkWell: Make card tappable to navigate to Pomodoro screen
                return InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PomodoroScreen(
                              focusService: widget.focusService))),
                  borderRadius: BorderRadius.circular(16),
                  // Card: Material elevated container
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getCardPadding(context))),
                    color: theme.cardTheme.color,
                    // Padding: Inner spacing
                    child: Padding(
                      padding: EdgeInsets.all(
                          ResponsiveUtils.getCardPadding(context)),
                      // Column: Vertical stack of icon/value row, title, info lines, progress bar
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Chart icon (left), hours badge (right)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Icon: Bar chart indicating study tracking
                              Icon(Icons.bar_chart_rounded,
                                  color: softBlue.withValues(alpha: 0.7),
                                  size: ResponsiveUtils.getIconSize(context)),
                              // Container: Badge showing study hours progress
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        ResponsiveUtils.isMobile(context)
                                            ? 8
                                            : 12,
                                    vertical: ResponsiveUtils.isMobile(context)
                                        ? 4
                                        : 6),
                                decoration: BoxDecoration(
                                  color: softBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                // Value text: "2.5/4 Hrs" formatted display
                                child: Text(value,
                                    style: TextStyle(
                                        color: softBlue.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            ResponsiveUtils.getSmallFontSize(
                                                context))),
                              ),
                            ],
                          ),
                          // Title: "Study Time"
                          Text('Study Time',
                              style: TextStyle(
                                  fontSize:
                                      ResponsiveUtils.getBodyFontSize(context),
                                  fontWeight: FontWeight.w500,
                                  color: onSurface.withValues(alpha: 0.85))),
                          const SizedBox(height: 4),
                          // Info line: Minutes persisted to database
                          Text(savedLine,
                              style: TextStyle(
                                  fontSize:
                                      ResponsiveUtils.getSmallFontSize(context),
                                  fontWeight: FontWeight.w500,
                                  color: onSurface.withValues(alpha: 0.7))),
                          // Conditional: Show sync timestamp if available
                          // Purpose: User feedback that timer data has been saved to cloud
                          if (syncLine != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(syncLine,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          onSurface.withValues(alpha: 0.45))),
                            ),
                          // LinearProgressIndicator: Visual progress bar for study goal
                          // Clamp value between 0-1 to prevent overflow past 100%
                          LinearProgressIndicator(
                            // Conditional: Prevent division by zero if goal is 0
                            value: goalMin == 0
                                ? 0
                                : (displayedMinutes / goalMin).clamp(0, 1),
                            // backgroundColor: Background track (1st color = unfilled portion)
                            backgroundColor: onSurface.withValues(alpha: 0.1),
                            // color: Foreground track (primary color = filled portion)
                            color: theme.colorScheme.primary,
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
