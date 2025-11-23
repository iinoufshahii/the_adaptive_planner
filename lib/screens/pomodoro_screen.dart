/// Pomodoro screen with customizable glowing circular timer.
/// Persists progress to Firebase via FocusTimerManager -> FocusService.
/// The manager updates Firestore each minute (and on pause/reset/phase complete).
/// This screen is the UI layer with settings dialog for custom break durations.
library;

import 'package:adaptive_planner/models/focus_session.dart';
import 'package:adaptive_planner/Service/focus_service.dart';
import 'package:adaptive_planner/Service/focus_timer_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dialogs/app_dialogs.dart';

/// Pomodoro screen with customizable glowing circular timer.
/// Persists progress to Firebase via FocusTimerManager -> FocusService.
/// The manager updates Firestore each minute (and on pause/reset/phase complete).
/// This screen is the UI layer with settings dialog for custom break durations.

class PomodoroScreen extends StatefulWidget {
  final FocusService focusService;
  const PomodoroScreen({super.key, required this.focusService});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  final FocusTimerManager _manager = FocusTimerManager();
  final FocusService _focusService = FocusService();
  late final AnimationController _pulseController;

  // Local override values for custom session settings
  int? _customShortBreakMinutes;
  int? _customLongBreakMinutes;

  // Study goal state
  late TextEditingController _studyGoalController;
  int _studyGoalHours = 4;

  @override
  void initState() {
    super.initState();
    _studyGoalController = TextEditingController(text: '4');
    _manager.addListener(_listener);
    if (_manager.prefs == null) {
      _manager.loadPrefs();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadStudyGoal();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manager.removeListener(_listener);
    _studyGoalController.dispose();
    super.dispose();
  }

  /// Format seconds to MM:SS format
  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Get total seconds for current phase based on manager prefs
  int _getPhaseTotalSeconds() {
    final prefs = _manager.prefs;
    if (prefs == null) return 1;

    switch (_manager.phase) {
      case PomodoroPhase.work:
        return prefs.workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return (_customShortBreakMinutes ?? prefs.shortBreakMinutes) * 60;
      case PomodoroPhase.longBreak:
        return (_customLongBreakMinutes ?? prefs.longBreakMinutes) * 60;
      case PomodoroPhase.idle:
        return prefs.workMinutes * 60;
    }
  }

  /// Get color based on current phase with theme awareness
  Color _getPhaseColor(ThemeData theme) {
    switch (_manager.phase) {
      case PomodoroPhase.work:
        return theme.colorScheme.primary;
      case PomodoroPhase.shortBreak:
        return theme.brightness == Brightness.dark
            ? Colors.cyan.shade300
            : Colors.teal.shade400;
      case PomodoroPhase.longBreak:
        return theme.brightness == Brightness.dark
            ? Colors.purple.shade300
            : Colors.purple.shade400;
      case PomodoroPhase.idle:
        return theme.colorScheme.secondary;
    }
  }

  /// Load the study goal from Firebase
  Future<void> _loadStudyGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await _focusService.focusPrefsStream(user.uid).first;
    if (mounted) {
      setState(() {
        _studyGoalHours = (prefs.dailyGoalMinutes / 60).ceil();
        _studyGoalController.text = _studyGoalHours.toString();
      });
    }
  }

  /// Save the study goal to Firebase
  Future<void> _saveStudyGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final goalHours = int.tryParse(_studyGoalController.text);
    if (goalHours == null || goalHours < 1 || goalHours > 24) {
      if (!mounted) return;
      await showFloatingBottomDialog(
        context,
        message: 'Please enter a valid hour (1-24)',
        type: AppMessageType.warning,
      );
      return;
    }

    try {
      final prefs = await _focusService.focusPrefsStream(user.uid).first;
      final updatedPrefs = UserFocusPrefs(
        userId: user.uid,
        dailyGoalMinutes: goalHours * 60,
        workMinutes: prefs.workMinutes,
        shortBreakMinutes: prefs.shortBreakMinutes,
        longBreakMinutes: prefs.longBreakMinutes,
        longBreakInterval: prefs.longBreakInterval,
      );

      await _focusService.updatePrefs(updatedPrefs);

      if (!mounted) return;
      setState(() {
        _studyGoalHours = goalHours;
      });

      await showFloatingBottomDialog(
        context,
        message:
            'Study goal updated to $goalHours hour${goalHours > 1 ? 's' : ''}',
        type: AppMessageType.success,
      );
    } catch (e) {
      if (!mounted) return;
      await showFloatingBottomDialog(
        context,
        message: 'Error updating goal: $e',
        type: AppMessageType.error,
      );
    }
  }

  /// Get phase display label
  String _getPhaseLabel() {
    switch (_manager.phase) {
      case PomodoroPhase.work:
        return 'WORK';
      case PomodoroPhase.shortBreak:
        return 'SHORT BREAK';
      case PomodoroPhase.longBreak:
        return 'LONG BREAK';
      case PomodoroPhase.idle:
        return 'READY';
    }
  }

  /// Show settings dialog for customizing break durations
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _PomodoroSettingsDialog(
        prefs: _manager.prefs,
        studyGoalHours: _studyGoalHours,
        studyGoalController: _studyGoalController,
        onSaveStudyGoal: _saveStudyGoal,
        onCustomBreaksSet: (shortBreak, longBreak) {
          setState(() {
            _customShortBreakMinutes = shortBreak;
            _customLongBreakMinutes = longBreak;
          });
        },
      ),
    );
  }

  /// Reset custom break settings for next session
  void _resetCustomBreaks() {
    setState(() {
      _customShortBreakMinutes = null;
      _customLongBreakMinutes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = _manager.phase;
    final remaining = _manager.remainingSeconds;
    final total = _getPhaseTotalSeconds();
    final progress = 1 - (remaining / total).clamp(0.0, 1.0);
    final color = _getPhaseColor(theme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (phase != PomodoroPhase.idle)
            IconButton(
              tooltip: 'Reset Session',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _manager.reset();
                _resetCustomBreaks();
              },
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing circular timer
                _buildGlowingTimer(theme, color, remaining, progress),
                const SizedBox(height: 48),

                // Control buttons
                _buildControlButtons(phase),
                const SizedBox(height: 32),

                // Session info and sync status
                _buildSessionInfo(theme, color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build glowing circular timer widget
  Widget _buildGlowingTimer(
    ThemeData theme,
    Color color,
    int remaining,
    double progress,
  ) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated glow effect
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final glowIntensity = 0.4 + (_pulseController.value * 0.6);
              final blurRadius = 50 * glowIntensity;
              final spreadRadius = 8 * glowIntensity;

              return Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4 * glowIntensity),
                      blurRadius: blurRadius,
                      spreadRadius: spreadRadius,
                    ),
                  ],
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.2 * glowIntensity),
                      color.withValues(alpha: 0.03),
                    ],
                  ),
                ),
              );
            },
          ),

          // Progress ring
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _TimerRingPainter(
                progress: progress,
                color: color,
              ),
            ),
          ),

          // Time and phase labels
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(remaining),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getPhaseLabel(),
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build control buttons (Play, Pause, Resume, Stop)
  Widget _buildControlButtons(PomodoroPhase phase) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (phase == PomodoroPhase.idle)
          ElevatedButton.icon(
            onPressed: _manager.startWork,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Work'),
          ),
        if (phase != PomodoroPhase.idle && !_manager.isPaused)
          ElevatedButton.icon(
            onPressed: _manager.pause,
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pause'),
          ),
        if (phase != PomodoroPhase.idle && _manager.isPaused)
          ElevatedButton.icon(
            onPressed: _manager.resume,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Resume'),
          ),
        if (phase != PomodoroPhase.idle)
          OutlinedButton.icon(
            onPressed: () {
              _manager.saveAndEnd();
              _resetCustomBreaks();
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Save & End'),
          ),
      ],
    );
  }

  /// Build session info and sync status
  Widget _buildSessionInfo(ThemeData theme, Color color) {
    final lastSync = _manager.lastSync;
    final syncText = lastSync == null
        ? 'Session started — syncing every minute'
        : 'Last sync: ${TimeOfDay.fromDateTime(lastSync).format(context)}';

    final customSettings =
        _customShortBreakMinutes != null || _customLongBreakMinutes != null;

    return Column(
      children: [
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 400),
          child: Text(
            syncText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (customSettings) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Custom breaks enabled',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for timer ring progress indicator
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _TimerRingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background ring (dimmed)
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc with gradient
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          color,
          color.withValues(alpha: 0.5),
          color,
        ],
        stops: const [0.0, 0.5, 1.0],
        startAngle: -3.1416 / 2,
        endAngle: 3 * 3.1416 / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    final sweepAngle = progress * 2 * 3.1416;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1416 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Settings dialog for customizing break durations
class _PomodoroSettingsDialog extends StatefulWidget {
  final UserFocusPrefs? prefs;
  final Function(int?, int?) onCustomBreaksSet;
  final int studyGoalHours;
  final TextEditingController studyGoalController;
  final Future<void> Function() onSaveStudyGoal;

  const _PomodoroSettingsDialog({
    required this.prefs,
    required this.onCustomBreaksSet,
    required this.studyGoalHours,
    required this.studyGoalController,
    required this.onSaveStudyGoal,
  });

  @override
  State<_PomodoroSettingsDialog> createState() =>
      _PomodoroSettingsDialogState();
}

class _PomodoroSettingsDialogState extends State<_PomodoroSettingsDialog> {
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  bool _isSavingGoal = false;

  @override
  void initState() {
    super.initState();
    _shortBreakMinutes = widget.prefs?.shortBreakMinutes ?? 5;
    _longBreakMinutes = widget.prefs?.longBreakMinutes ?? 15;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Pomodoro Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Break Duration Section
            Text(
              'Break Duration',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set custom break durations for this session.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Short break duration slider
            _buildBreakSlider(
              label: 'Short Break',
              value: _shortBreakMinutes.toDouble(),
              onChanged: (val) =>
                  setState(() => _shortBreakMinutes = val.toInt()),
              min: 1,
              max: 15,
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Long break duration slider
            _buildBreakSlider(
              label: 'Long Break',
              value: _longBreakMinutes.toDouble(),
              onChanged: (val) =>
                  setState(() => _longBreakMinutes = val.toInt()),
              min: 5,
              max: 30,
              theme: theme,
            ),
            const SizedBox(height: 16),

            // Info box for breaks
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'ℹ️ Custom breaks only apply to the current session and do not affect saved work minutes.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Daily Study Goal Section
            Text(
              'Daily Study Goal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.studyGoalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hours per day',
                      suffixText: 'hrs',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSavingGoal
                      ? null
                      : () async {
                          setState(() => _isSavingGoal = true);
                          await widget.onSaveStudyGoal();
                          if (mounted) {
                            setState(() => _isSavingGoal = false);
                          }
                        },
                  icon: _isSavingGoal
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current goal: ${widget.studyGoalHours} hour${widget.studyGoalHours != 1 ? 's' : ''} (${widget.studyGoalHours * 60} minutes)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCustomBreaksSet(_shortBreakMinutes, _longBreakMinutes);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  /// Build a slider for break duration adjustment
  Widget _buildBreakSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${value.toInt()} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / 1).toInt(),
          label: '${value.toInt()} min',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
