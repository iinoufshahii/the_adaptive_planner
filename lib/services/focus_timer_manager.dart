// lib/services/focus_timer_manager.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_planner/models/focus_session.dart';
import 'package:adaptive_planner/services/focus_service.dart';

enum PomodoroPhase { idle, work, shortBreak, longBreak }

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
  PomodoroPhase get phase => _phase;
  int get remainingSeconds => _remainingSeconds;
  bool get isPaused => _isPaused;
  UserFocusPrefs? get prefs => _prefs;
  int get savedCurrentBlockMinutes {
    if (_lastPersistedDate == null) return 0;
    final now = DateTime.now();
    if (_lastPersistedDate!.year != now.year ||
        _lastPersistedDate!.month != now.month ||
        _lastPersistedDate!.day != now.day) {
      return 0; // Do not carry over yesterday's minutes onto today's dashboard
    }
    return _lastPersistedMinutes;
  }

  DateTime? get lastSync => _lastSync;

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
        final elapsedMinutes =
            DateTime.now().difference(_phaseStart!).inMinutes;
        if (elapsedMinutes > _lastPersistedMinutes) {
          _updateActiveSession(elapsedMinutes);
        }
      }
    } else {
      _onPhaseComplete();
    }
    notifyListeners();
  }

  void startWork() {
    if (_prefs == null) return;
    _phase = PomodoroPhase.work;
    _isPaused = false;
    _remainingSeconds = _prefs!.workMinutes * 60;
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
    if (user == null || _phaseStart == null) return;
    final session = FocusSession(
      userId: user.uid,
      start: _phaseStart!,
      end: _phaseStart!, // Temporary end time
      durationMinutes: 0,
    );
    _activeSessionId = await _focusService.createSession(session);
  }

  void pause() {
    if (_phase == PomodoroPhase.idle) return;
    _isPaused = true;
    _saveProgress();
    notifyListeners();
  }

  void resume() {
    if (_phase == PomodoroPhase.idle) return;
    _isPaused = false;
    notifyListeners();
  }

  void reset({bool clearSaved = true}) {
    _ticker?.cancel();
    _phase = PomodoroPhase.idle;
    if (_prefs != null) {
      _remainingSeconds = _prefs!.workMinutes * 60;
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

  /// Persist current progress (if any minutes elapsed) and end the session
  /// without wiping the saved minutes from the dashboard progress until a new
  /// work session starts.
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
    if (_activeSessionId == null || _phaseStart == null) return;
    final duration = DateTime.now().difference(_phaseStart!).inMinutes;
    await _focusService.updateSession(
      _activeSessionId!,
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
      if (_completedBlocks % _prefs!.longBreakInterval == 0) {
        _phase = PomodoroPhase.longBreak;
        _remainingSeconds = _prefs!.longBreakMinutes * 60;
      } else {
        _phase = PomodoroPhase.shortBreak;
        _remainingSeconds = _prefs!.shortBreakMinutes * 60;
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
