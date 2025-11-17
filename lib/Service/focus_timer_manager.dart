// lib/services/focus_timer_manager.dart

import 'dart:async';

import 'package:adaptive_planner/models/focus_session.dart';
import 'package:adaptive_planner/Service/focus_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Represents different phases of the Pomodoro timer cycle.
enum PomodoroPhase {
  /// No active session
  idle,

  /// Active work session
  work,

  /// Short break (5 minutes)
  shortBreak,

  /// Long break (15 minutes)
  longBreak
}

/// Manages Pomodoro focus timer state and persistence.
///
/// Provides a singleton instance that tracks focus sessions across the app.
/// Automatically persists session data to Firestore and provides real-time
/// updates to listeners about timer progress and phase changes.
///
/// Usage:
/// ```dart
/// final manager = FocusTimerManager();
/// await manager.loadPrefs();
/// manager.startWork();
/// manager.addListener(() {
///   print('Time remaining: ${manager.remainingSeconds}s');
/// });
/// ```
class FocusTimerManager extends ChangeNotifier {
  static final FocusTimerManager _instance = FocusTimerManager._internal();
  factory FocusTimerManager() => _instance;
  FocusTimerManager._internal();

  final FocusService _focusService = FocusService();
  Timer? _ticker;
  DateTime? _phaseStart;
  int _remainingSeconds = 0;
  PomodoroPhase _phase = PomodoroPhase.idle;
  int _completedBlocks = 0;
  UserFocusPrefs? _prefs;
  bool _isPaused = false;
  String? _activeSessionId;
  int _lastPersistedMinutes = 0;
  DateTime? _lastSync;
  DateTime?
      _lastPersistedDate; // Tracks the calendar day of the last persisted minutes

  // Public getters
  /// Current phase of the Pomodoro cycle.
  PomodoroPhase get phase => _phase;

  /// Remaining seconds in current phase.
  int get remainingSeconds => _remainingSeconds;

  /// Whether the timer is paused.
  bool get isPaused => _isPaused;

  /// User's focus session preferences (work/break durations, etc).
  UserFocusPrefs? get prefs => _prefs;

  /// Minutes completed in current work block, resets daily.
  ///
  /// Returns 0 if it's a new day (to prevent carryover from previous day).
  int get savedCurrentBlockMinutes {
    final lastDate = _lastPersistedDate;
    if (lastDate == null) return 0;
    final now = DateTime.now();
    if (lastDate.year != now.year ||
        lastDate.month != now.month ||
        lastDate.day != now.day) {
      return 0; // Do not carry over yesterday's minutes onto today's dashboard
    }
    return _lastPersistedMinutes;
  }

  /// Timestamp of last sync with Firestore.
  DateTime? get lastSync => _lastSync;

  /// Loads user's focus preferences from Firestore.
  ///
  /// Must be called during app initialization. Returns early if no user
  /// is authenticated. Triggers [notifyListeners] on completion.
  Future<void> loadPrefs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _prefs = await _focusService.focusPrefsStream(user.uid).first;
    reset();
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (_isPaused) return;
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      if (_phase == PomodoroPhase.work &&
          _phaseStart != null &&
          _activeSessionId != null) {
        final start = _phaseStart;
        if (start != null) {
          final elapsedMinutes = DateTime.now().difference(start).inMinutes;
          if (elapsedMinutes > _lastPersistedMinutes) {
            _updateActiveSession(elapsedMinutes);
          }
        }
      }
    } else {
      _onPhaseComplete();
    }
    notifyListeners();
  }

  /// Starts a new work session with configured duration.
  ///
  /// Creates a new focus session record in Firestore and begins the
  /// countdown timer. Returns early if preferences are not loaded.
  void startWork() {
    final userPrefs = _prefs;
    if (userPrefs == null) return;
    _phase = PomodoroPhase.work;
    _isPaused = false;
    _remainingSeconds = userPrefs.workMinutes * 60;
    _phaseStart = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
    _createNewSession();
    _lastPersistedMinutes = 0;
    _lastSync = null;
    notifyListeners();
  }

  Future<void> _createNewSession() async {
    final user = FirebaseAuth.instance.currentUser;
    final start = _phaseStart;
    if (user == null || start == null) return;
    final session = FocusSession(
      userId: user.uid,
      start: start,
      end: start, // Temporary end time
      durationMinutes: 0,
    );
    _activeSessionId = await _focusService.createSession(session);
  }

  /// Pauses the current phase without resetting.
  ///
  /// Saves current progress to Firestore before pausing.
  void pause() {
    if (_phase == PomodoroPhase.idle) return;
    _isPaused = true;
    _saveProgress();
    notifyListeners();
  }

  /// Resumes a paused timer.
  ///
  /// Returns early if no active phase is running.
  void resume() {
    if (_phase == PomodoroPhase.idle) return;
    _isPaused = false;
    notifyListeners();
  }

  /// Resets the timer to idle state.
  ///
  /// Stops any active timer and cancels the current session.
  /// If [clearSaved] is true, also clears persisted progress.
  void reset({bool clearSaved = true}) {
    _ticker?.cancel();
    _phase = PomodoroPhase.idle;
    final userPrefs = _prefs;
    if (userPrefs != null) {
      _remainingSeconds = userPrefs.workMinutes * 60;
    }
    _isPaused = false;
    _completedBlocks = 0;
    _activeSessionId = null;
    if (clearSaved) {
      _lastPersistedMinutes = 0;
      _lastPersistedDate = null;
      _lastSync = null;
    }
    notifyListeners();
  }

  /// Saves progress and ends the current session without clearing saved minutes.
  ///
  /// Persists the current session duration to Firestore. Unlike [reset],
  /// this preserves the [savedCurrentBlockMinutes] for dashboard display.
  Future<void> saveAndEnd() async {
    if (_phase == PomodoroPhase.work ||
        _phase == PomodoroPhase.shortBreak ||
        _phase == PomodoroPhase.longBreak) {
      await _saveProgress();
    }
    reset(clearSaved: false); // keep lastPersistedMinutes for dashboard display
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final sessionId = _activeSessionId;
    final start = _phaseStart;
    if (sessionId == null || start == null) return;
    final duration = DateTime.now().difference(start).inMinutes;
    await _focusService.updateSession(
      sessionId,
      end: DateTime.now(),
      durationMinutes: duration,
    );
    _lastPersistedMinutes = duration;
    _lastPersistedDate = DateTime.now();
    _lastSync = DateTime.now();
  }

  Future<void> _updateActiveSession(int minutes) async {
    if (_activeSessionId == null) return;
    _lastPersistedMinutes = minutes;
    _lastPersistedDate = DateTime.now();
    _lastSync = DateTime.now();
    // Fire and forget
    unawaited(_focusService.updateSession(
      _activeSessionId!,
      end: DateTime.now(),
      durationMinutes: minutes,
    ));
  }

  void _onPhaseComplete() {
    _saveProgress();
    _ticker?.cancel();
    if (_phase == PomodoroPhase.work) {
      _completedBlocks++;
      final userPrefs = _prefs;
      if (userPrefs != null) {
        if (_completedBlocks % userPrefs.longBreakInterval == 0) {
          _phase = PomodoroPhase.longBreak;
          _remainingSeconds = userPrefs.longBreakMinutes * 60;
        } else {
          _phase = PomodoroPhase.shortBreak;
          _remainingSeconds = userPrefs.shortBreakMinutes * 60;
        }
      }
    } else {
      _phase = PomodoroPhase.idle;
      reset();
      return;
    }
    _phaseStart = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
