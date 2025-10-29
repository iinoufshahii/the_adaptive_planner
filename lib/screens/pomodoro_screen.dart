// lib/screens/pomodoro_screen.dart

import 'package:flutter/material.dart';
import 'package:adaptive_planner/services/focus_timer_manager.dart';
import 'package:adaptive_planner/services/focus_service.dart';

/// Pomodoro screen with glowing circular timer that persists progress to Firebase
/// via FocusTimerManager -> FocusService. The manager updates Firestore each
/// minute (and on pause/reset/phase complete). This screen is purely a UI layer.

class PomodoroScreen extends StatefulWidget {
  final FocusService focusService;
  const PomodoroScreen({super.key, required this.focusService});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  final FocusTimerManager _manager = FocusTimerManager();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _manager.addListener(_listener);
    if (_manager.prefs == null) {
      _manager.loadPrefs();
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manager.removeListener(_listener);
    super.dispose();
  }

  String _format(int secs) {
    final m = (secs / 60).floor().toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int _phaseTotalSeconds() {
    final prefs = _manager.prefs;
    if (prefs == null) return 1;
    switch (_manager.phase) {
      case PomodoroPhase.work:
        return prefs.workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return prefs.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return prefs.longBreakMinutes * 60;
      case PomodoroPhase.idle:
        return prefs.workMinutes * 60;
    }
  }

  Color _phaseColor(ThemeData theme) {
    switch (_manager.phase) {
      case PomodoroPhase.work:
        return theme.colorScheme.primary;
      case PomodoroPhase.shortBreak:
        return Colors.tealAccent.shade400;
      case PomodoroPhase.longBreak:
        return Colors.purpleAccent.shade200;
      case PomodoroPhase.idle:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = _manager.phase;
    final remaining = _manager.remainingSeconds;
    final total = _phaseTotalSeconds();
    final progress = 1 - (remaining / total).clamp(0.0, 1.0);
    final color = _phaseColor(theme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Session'),
        actions: [
          if (phase != PomodoroPhase.idle)
            IconButton(
              tooltip: 'Reset Session',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _manager.reset,
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing circular timer
            SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final glow = 0.4 + (_pulseController.value * 0.6);
                      return Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35 * glow),
                              blurRadius: 45 * glow,
                              spreadRadius: 5 * glow,
                            ),
                          ],
                          gradient: RadialGradient(
                            colors: [
                              color.withOpacity(0.15 * glow),
                              color.withOpacity(0.02),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Progress ring
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _RingPainter(progress: progress, color: color),
                    ),
                  ),
                  // Time + Phase labels
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _format(remaining),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        phase.toString().split('.').last.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 16,
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
                    onPressed: _manager.saveAndEnd,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Save & End'),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _PersistenceHint(manager: _manager, color: color),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final background = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final foreground = Paint()
      ..shader = SweepGradient(
        colors: [color, color.withOpacity(0.2), color],
        stops: const [0.0, 0.75, 1.0],
        startAngle: -3.14 / 2,
        endAngle: 3 * 3.14 / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Draw background ring
    canvas.drawCircle(center, radius, background);
    // Draw arc
    final sweep = progress * 2 * 3.1415926535;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      sweep,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.color != color;
}

class _PersistenceHint extends StatelessWidget {
  final FocusTimerManager manager;
  final Color color;
  const _PersistenceHint({required this.manager, required this.color});

  @override
  Widget build(BuildContext context) {
    final lastSync = manager.lastSync;
    final text = lastSync == null
        ? 'Session started — syncing every minute'
        : 'Last sync: ${TimeOfDay.fromDateTime(lastSync).format(context)}';
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 400),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
            fontWeight: FontWeight.w500,
          color: color.withOpacity(0.75),
          letterSpacing: 0.3,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}