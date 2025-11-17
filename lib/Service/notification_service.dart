import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification preference model for storing user notification settings
class NotificationPreference {
  final bool enableNotifications;
  final bool enableDailyJournal;
  final bool enableMoodCheck;
  final bool enableTasksDueToday;
  final int taskDueInDays;
  final bool enableTasksDueIn;
  final int journalHour;
  final int journalMinute;
  final int moodCheckHour;
  final int moodCheckMinute;
  final int tasksDueTodayHour;
  final int tasksDueTodayMinute;

  NotificationPreference({
    this.enableNotifications = true,
    this.enableDailyJournal = true,
    this.enableMoodCheck = true,
    this.enableTasksDueToday = true,
    this.taskDueInDays = 2,
    this.enableTasksDueIn = true,
    this.journalHour = 8,
    this.journalMinute = 0,
    this.moodCheckHour = 12,
    this.moodCheckMinute = 0,
    this.tasksDueTodayHour = 9,
    this.tasksDueTodayMinute = 0,
  });

  Map<String, dynamic> toJson() => {
        'enableNotifications': enableNotifications,
        'enableDailyJournal': enableDailyJournal,
        'enableMoodCheck': enableMoodCheck,
        'enableTasksDueToday': enableTasksDueToday,
        'taskDueInDays': taskDueInDays,
        'enableTasksDueIn': enableTasksDueIn,
        'journalHour': journalHour,
        'journalMinute': journalMinute,
        'moodCheckHour': moodCheckHour,
        'moodCheckMinute': moodCheckMinute,
        'tasksDueTodayHour': tasksDueTodayHour,
        'tasksDueTodayMinute': tasksDueTodayMinute,
      };

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      enableNotifications: json['enableNotifications'] ?? true,
      enableDailyJournal: json['enableDailyJournal'] ?? true,
      enableMoodCheck: json['enableMoodCheck'] ?? true,
      enableTasksDueToday: json['enableTasksDueToday'] ?? true,
      taskDueInDays: json['taskDueInDays'] ?? 2,
      enableTasksDueIn: json['enableTasksDueIn'] ?? true,
      journalHour: json['journalHour'] ?? 8,
      journalMinute: json['journalMinute'] ?? 0,
      moodCheckHour: json['moodCheckHour'] ?? 12,
      moodCheckMinute: json['moodCheckMinute'] ?? 0,
      tasksDueTodayHour: json['tasksDueTodayHour'] ?? 9,
      tasksDueTodayMinute: json['tasksDueTodayMinute'] ?? 0,
    );
  }

  NotificationPreference copyWith({
    bool? enableNotifications,
    bool? enableDailyJournal,
    bool? enableMoodCheck,
    bool? enableTasksDueToday,
    int? taskDueInDays,
    bool? enableTasksDueIn,
    int? journalHour,
    int? journalMinute,
    int? moodCheckHour,
    int? moodCheckMinute,
    int? tasksDueTodayHour,
    int? tasksDueTodayMinute,
  }) {
    return NotificationPreference(
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableDailyJournal: enableDailyJournal ?? this.enableDailyJournal,
      enableMoodCheck: enableMoodCheck ?? this.enableMoodCheck,
      enableTasksDueToday: enableTasksDueToday ?? this.enableTasksDueToday,
      taskDueInDays: taskDueInDays ?? this.taskDueInDays,
      enableTasksDueIn: enableTasksDueIn ?? this.enableTasksDueIn,
      journalHour: journalHour ?? this.journalHour,
      journalMinute: journalMinute ?? this.journalMinute,
      moodCheckHour: moodCheckHour ?? this.moodCheckHour,
      moodCheckMinute: moodCheckMinute ?? this.moodCheckMinute,
      tasksDueTodayHour: tasksDueTodayHour ?? this.tasksDueTodayHour,
      tasksDueTodayMinute: tasksDueTodayMinute ?? this.tasksDueTodayMinute,
    );
  }
}

/// Manages local notifications for the Adaptive Planner app
/// Handles scheduling of daily journal reminders, mood checks, and task notifications
class NotificationService extends ChangeNotifier {
  static const String _prefsKey = 'notification_preferences';

  late NotificationPreference _preferences;
  final AwesomeNotifications _awesomeNotifications = AwesomeNotifications();

  NotificationPreference get preferences => _preferences;

  NotificationService() {
    _preferences = NotificationPreference();
  }

  /// Initialize notification service and load preferences
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _awesomeNotifications.initialize(
        null,
        [
          NotificationChannel(
            channelGroupKey: 'basic_channel_group',
            channelKey: 'basic_channel',
            channelName: 'Basic notifications',
            channelDescription: 'Notification channel for basic reminders',
            defaultColor: const Color.fromARGB(255, 17, 173, 235),
            ledColor: const Color.fromARGB(255, 17, 173, 235),
          ),
        ],
        channelGroups: [
          NotificationChannelGroup(
            channelGroupKey: 'basic_channel_group',
            channelGroupName: 'Basic group',
          ),
        ],
      );

      // Request notification permissions
      await _awesomeNotifications.requestPermissionToSendNotifications();

      // Load saved preferences
      await _loadPreferences();

      // Schedule notifications based on preferences
      await _scheduleNotifications();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Load notification preferences from shared preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          // Try to parse as JSON map
          final json = _parseJson(jsonStr);
          _preferences = NotificationPreference.fromJson(json);
        } catch (e) {
          print('Error parsing preferences JSON: $e');
          _preferences = NotificationPreference();
        }
      }
    } catch (e) {
      print('Error loading preferences: $e');
      _preferences = NotificationPreference();
    }
  }

  /// Parse JSON string to map
  Map<String, dynamic> _parseJson(String jsonStr) {
    final Map<String, dynamic> result = {};

    // Simple JSON parser for basic types
    if (jsonStr.startsWith('{') && jsonStr.endsWith('}')) {
      final content = jsonStr.substring(1, jsonStr.length - 1);
      final pairs = content.split(',');

      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().replaceAll('"', '');
          final value = keyValue[1].trim();

          if (value == 'true') {
            result[key] = true;
          } else if (value == 'false') {
            result[key] = false;
          } else if (int.tryParse(value) != null) {
            result[key] = int.parse(value);
          } else {
            result[key] = value.replaceAll('"', '');
          }
        }
      }
    }

    return result;
  }

  /// Save notification preferences to shared preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _jsonEncode(_preferences.toJson()));
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  /// Simple JSON encoder for saving preferences
  String _jsonEncode(Map<String, dynamic> data) {
    final entries = data.entries
        .map((e) => '"${e.key}":${_encodeValue(e.value)}')
        .join(',');
    return '{$entries}';
  }

  String _encodeValue(dynamic value) {
    if (value is String) return '"$value"';
    if (value is bool) return value ? 'true' : 'false';
    if (value is int) return value.toString();
    return 'null';
  }

  /// Update notification preferences and reschedule notifications
  Future<void> updatePreferences(NotificationPreference newPreferences) async {
    _preferences = newPreferences;
    await _savePreferences();
    await _cancelAllNotifications();
    await _scheduleNotifications();
    notifyListeners();
  }

  /// Schedule all active notifications based on preferences
  Future<void> _scheduleNotifications() async {
    try {
      // Daily journal reminder at 8 AM
      if (_preferences.enableDailyJournal) {
        await _scheduleDailyJournalReminder();
      }

      // Mood check reminder at 12 PM (noon)
      if (_preferences.enableMoodCheck) {
        await _scheduleMoodCheckReminder();
      }

      // Tasks due today reminder at 9 AM
      if (_preferences.enableTasksDueToday) {
        await _scheduleTasksDueTodayReminder();
      }

      // Tasks due in N days reminder
      if (_preferences.enableTasksDueIn) {
        await _scheduleTasksDueInReminder();
      }
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  /// Schedule daily journal reminder
  Future<void> _scheduleDailyJournalReminder() async {
    try {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _preferences.journalHour,
        _preferences.journalMinute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await _awesomeNotifications.createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'basic_channel',
          title: 'Time to Journal',
          body: 'Reflect on your day and capture your thoughts',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          wakeUpScreen: true,
        ),
        schedule: NotificationCalendar(
          year: scheduledDateTime.year,
          month: scheduledDateTime.month,
          day: scheduledDateTime.day,
          hour: _preferences.journalHour,
          minute: _preferences.journalMinute,
          second: 0,
          allowWhileIdle: true,
          repeats: true,
        ),
      );
    } catch (e) {
      print('Error scheduling journal reminder: $e');
    }
  }

  /// Schedule mood check reminder
  Future<void> _scheduleMoodCheckReminder() async {
    try {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _preferences.moodCheckHour,
        _preferences.moodCheckMinute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await _awesomeNotifications.createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: 'basic_channel',
          title: 'Mood Check-in',
          body: 'How are you feeling right now?',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          wakeUpScreen: false,
        ),
        schedule: NotificationCalendar(
          year: scheduledDateTime.year,
          month: scheduledDateTime.month,
          day: scheduledDateTime.day,
          hour: _preferences.moodCheckHour,
          minute: _preferences.moodCheckMinute,
          second: 0,
          allowWhileIdle: true,
          repeats: true,
        ),
      );
    } catch (e) {
      print('Error scheduling mood check reminder: $e');
    }
  }

  /// Schedule tasks due today reminder
  Future<void> _scheduleTasksDueTodayReminder() async {
    try {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _preferences.tasksDueTodayHour,
        _preferences.tasksDueTodayMinute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await _awesomeNotifications.createNotification(
        content: NotificationContent(
          id: 3,
          channelKey: 'basic_channel',
          title: 'Tasks Due Today',
          body: 'Check your tasks due today',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          wakeUpScreen: false,
        ),
        schedule: NotificationCalendar(
          year: scheduledDateTime.year,
          month: scheduledDateTime.month,
          day: scheduledDateTime.day,
          hour: _preferences.tasksDueTodayHour,
          minute: _preferences.tasksDueTodayMinute,
          second: 0,
          allowWhileIdle: true,
          repeats: true,
        ),
      );
    } catch (e) {
      print('Error scheduling tasks due today reminder: $e');
    }
  }

  /// Schedule tasks due in N days reminder
  Future<void> _scheduleTasksDueInReminder() async {
    try {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        10,
        0,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await _awesomeNotifications.createNotification(
        content: NotificationContent(
          id: 4,
          channelKey: 'basic_channel',
          title: 'Upcoming Tasks',
          body:
              'Tasks due in ${_preferences.taskDueInDays} days - start planning!',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          wakeUpScreen: false,
        ),
        schedule: NotificationCalendar(
          year: scheduledDateTime.year,
          month: scheduledDateTime.month,
          day: scheduledDateTime.day,
          hour: 10,
          minute: 0,
          second: 0,
          allowWhileIdle: true,
          repeats: true,
        ),
      );
    } catch (e) {
      print('Error scheduling tasks due in reminder: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> _cancelAllNotifications() async {
    try {
      await _awesomeNotifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  /// Send a test notification
  Future<void> sendTestNotification() async {
    try {
      await _awesomeNotifications.createNotification(
        content: NotificationContent(
          id: 999,
          channelKey: 'basic_channel',
          title: 'Test Notification',
          body: 'Your notification settings are working!',
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
        ),
      );
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }
}
