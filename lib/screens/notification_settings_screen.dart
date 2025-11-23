/// Modern notification settings screen with customizable time preferences.
/// Uses app theme for consistent design with glass effect cards and responsive layout.
/// Allows users to configure notification times and enable/disable individual notifications.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../dialogs/app_dialogs.dart';
import '../Service/notification_service.dart';
import '../Theme/App_Theme.dart';
import '../Widgets/Responsive_widget.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationService _notificationService;
  late NotificationPreference _preferences;

  @override
  void initState() {
    super.initState();
    // Get the NotificationService from Provider
    _notificationService =
        Provider.of<NotificationService>(context, listen: false);
    _preferences = _notificationService.preferences;
  }

  Future<void> _selectTime(BuildContext context, String title,
      TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: deepAqua,
              dialBackgroundColor:
                  Theme.of(context).colorScheme.surfaceContainer,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _updateJournalTime(TimeOfDay time) {
    final newPreferences = _preferences.copyWith(
      journalHour: time.hour,
      journalMinute: time.minute,
    );
    _notificationService.updatePreferences(newPreferences);
    setState(() => _preferences = newPreferences);
  }

  void _updateMoodTime(TimeOfDay time) {
    final newPreferences = _preferences.copyWith(
      moodCheckHour: time.hour,
      moodCheckMinute: time.minute,
    );
    _notificationService.updatePreferences(newPreferences);
    setState(() => _preferences = newPreferences);
  }

  void _updateTasksDueTodayTime(TimeOfDay time) {
    final newPreferences = _preferences.copyWith(
      tasksDueTodayHour: time.hour,
      tasksDueTodayMinute: time.minute,
    );
    _notificationService.updatePreferences(newPreferences);
    setState(() => _preferences = newPreferences);
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 800 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.all(padding.toDouble()),
            children: [
              // Master Toggle Section
              _buildMasterToggleCard(theme, bodyFontSize, padding),
              const SizedBox(height: 24),

              // Daily Journal Notification
              if (_preferences.enableNotifications)
                _buildNotificationCard(
                  context: context,
                  theme: theme,
                  title: 'Daily Journal',
                  subtitle: 'Get reminded to journal each day',
                  icon: Icons.edit_note_outlined,
                  isEnabled: _preferences.enableDailyJournal,
                  onToggle: (value) {
                    final newPreferences =
                        _preferences.copyWith(enableDailyJournal: value);
                    _notificationService.updatePreferences(newPreferences);
                    setState(() => _preferences = newPreferences);
                  },
                  timeDisplay: _formatTime(
                      _preferences.journalHour, _preferences.journalMinute),
                  onTimePressed: () => _selectTime(
                    context,
                    'Journal Time',
                    TimeOfDay(
                      hour: _preferences.journalHour,
                      minute: _preferences.journalMinute,
                    ),
                    _updateJournalTime,
                  ),
                  bodyFontSize: bodyFontSize,
                  padding: padding,
                ),
              if (_preferences.enableNotifications) const SizedBox(height: 16),

              // Mood Check-in Notification
              if (_preferences.enableNotifications)
                _buildNotificationCard(
                  context: context,
                  theme: theme,
                  title: 'Mood Check-in',
                  subtitle: 'Daily mood tracking reminder',
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  isEnabled: _preferences.enableMoodCheck,
                  onToggle: (value) {
                    final newPreferences =
                        _preferences.copyWith(enableMoodCheck: value);
                    _notificationService.updatePreferences(newPreferences);
                    setState(() => _preferences = newPreferences);
                  },
                  timeDisplay: _formatTime(
                      _preferences.moodCheckHour, _preferences.moodCheckMinute),
                  onTimePressed: () => _selectTime(
                    context,
                    'Mood Check Time',
                    TimeOfDay(
                      hour: _preferences.moodCheckHour,
                      minute: _preferences.moodCheckMinute,
                    ),
                    _updateMoodTime,
                  ),
                  bodyFontSize: bodyFontSize,
                  padding: padding,
                ),
              if (_preferences.enableNotifications) const SizedBox(height: 16),

              // Tasks Due Today Notification
              if (_preferences.enableNotifications)
                _buildNotificationCard(
                  context: context,
                  theme: theme,
                  title: 'Tasks Due Today',
                  subtitle: 'Review your daily tasks',
                  icon: Icons.check_circle_outline,
                  isEnabled: _preferences.enableTasksDueToday,
                  onToggle: (value) {
                    final newPreferences =
                        _preferences.copyWith(enableTasksDueToday: value);
                    _notificationService.updatePreferences(newPreferences);
                    setState(() => _preferences = newPreferences);
                  },
                  timeDisplay: _formatTime(_preferences.tasksDueTodayHour,
                      _preferences.tasksDueTodayMinute),
                  onTimePressed: () => _selectTime(
                    context,
                    'Tasks Due Today Time',
                    TimeOfDay(
                      hour: _preferences.tasksDueTodayHour,
                      minute: _preferences.tasksDueTodayMinute,
                    ),
                    _updateTasksDueTodayTime,
                  ),
                  bodyFontSize: bodyFontSize,
                  padding: padding,
                ),
              if (_preferences.enableNotifications) const SizedBox(height: 16),

              // Upcoming Tasks Notification
              if (_preferences.enableNotifications)
                _buildUpcomingTasksCard(
                  context: context,
                  theme: theme,
                  bodyFontSize: bodyFontSize,
                  padding: padding,
                ),
              if (_preferences.enableNotifications) const SizedBox(height: 24),

              // Test Notification Button
              if (_preferences.enableNotifications)
                _buildTestButton(context, theme, bodyFontSize, padding),
              const SizedBox(height: 24),

              // Info Text
              if (!_preferences.enableNotifications)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding * 0.5),
                  child: Container(
                    padding: EdgeInsets.all(padding),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enable notifications in Settings to use these features',
                            style: TextStyle(
                              fontSize: bodyFontSize * 0.9,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterToggleCard(
      ThemeData theme, double bodyFontSize, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: deepAqua.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: deepAqua,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Notifications',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _preferences.enableNotifications
                      ? 'Notifications enabled'
                      : 'Notifications disabled',
                  style: TextStyle(
                    fontSize: bodyFontSize * 0.85,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _preferences.enableNotifications,
            onChanged: (value) {
              final newPreferences =
                  _preferences.copyWith(enableNotifications: value);
              Provider.of<NotificationService>(context, listen: false)
                  .updatePreferences(newPreferences);
              setState(() => _preferences = newPreferences);
            },
            activeThumbColor: deepAqua,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required Function(bool) onToggle,
    required String timeDisplay,
    required VoidCallback onTimePressed,
    required double bodyFontSize,
    required double padding,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? deepAqua.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? deepAqua : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: bodyFontSize * 0.85,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: deepAqua,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onTimePressed,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: padding * 0.5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: deepAqua.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Set time',
                      style: TextStyle(
                        fontSize: bodyFontSize * 0.9,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          timeDisplay,
                          style: TextStyle(
                            fontSize: bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: deepAqua,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.access_time,
                          color: deepAqua,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingTasksCard({
    required BuildContext context,
    required ThemeData theme,
    required double bodyFontSize,
    required double padding,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _preferences.enableTasksDueIn
                      ? softBlue.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: _preferences.enableTasksDueIn ? softBlue : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Tasks',
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Tasks due in the next days',
                      style: TextStyle(
                        fontSize: bodyFontSize * 0.85,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences.enableTasksDueIn,
                onChanged: (value) {
                  final newPreferences =
                      _preferences.copyWith(enableTasksDueIn: value);
                  Provider.of<NotificationService>(context, listen: false)
                      .updatePreferences(newPreferences);
                  setState(() => _preferences = newPreferences);
                },
                activeThumbColor: softBlue,
              ),
            ],
          ),
          if (_preferences.enableTasksDueIn) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding * 0.5),
                child: DropdownButton<int>(
                  value: _preferences.taskDueInDays,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  items: [1, 2, 3, 4, 5, 7, 10, 14]
                      .map((days) => DropdownMenuItem(
                            value: days,
                            child: Text(
                              'Tasks due in $days day${days > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: bodyFontSize * 0.9,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final newPreferences =
                          _preferences.copyWith(taskDueInDays: value);
                      Provider.of<NotificationService>(context, listen: false)
                          .updatePreferences(newPreferences);
                      setState(() => _preferences = newPreferences);
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestButton(BuildContext context, ThemeData theme,
      double bodyFontSize, double padding) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await Provider.of<NotificationService>(context, listen: false)
                .sendTestNotification();
            if (!mounted) return;
            await showFloatingBottomDialog(
              context,
              message: 'Test notification sent!',
              type: AppMessageType.success,
            );
          } catch (e) {
            if (!mounted) return;
            await showFloatingBottomDialog(
              context,
              message: 'Failed to send test notification: $e',
              type: AppMessageType.error,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: deepAqua,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: padding * 1.5,
            vertical: padding * 0.75,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.notifications_none_outlined),
        label: Text(
          'Send Test Notification',
          style: TextStyle(
            fontSize: bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
