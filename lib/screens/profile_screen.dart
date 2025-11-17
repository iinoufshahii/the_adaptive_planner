/// User profile screen displaying user stats, mood trends, study hours, and streak.
/// Shows charts (line/bar) for mood and study time, mood streak counter, avatar upload.
/// Allows name editing and provides mood/study statistics with daily/weekly/monthly views.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../dialogs/Error.dart';
import '../models/mood_check_in.dart';
import '../Service/mood_service.dart';
import '../Widgets/Responsive_widget.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _updatingName = false;
  bool _uploadingAvatar = false;
  final MoodService _moodService = MoodService();
  final ImagePicker _imagePicker = ImagePicker();
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  int? _streak;
  String _chartPeriod = 'week'; // 'week', 'month', 'year'
  String? _lastCheckInEmoji;
  DateTime? _lastCheckInDate;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  ImageProvider? _getAvatarImage(String? photoURL) {
    if (photoURL == null) return null;

    if (photoURL.startsWith('data:image')) {
      // Handle base64 images
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding base64 image: $e');
        return null;
      }
    } else {
      // Handle regular URLs
      return NetworkImage(photoURL);
    }
  }

  Future<void> _loadStreak() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final streak = await _moodService.currentStreak(user.uid);
      await _loadLatestCheckIn(user.uid);
      if (mounted) setState(() => _streak = streak);
    } catch (e) {
      print('Error loading streak: $e');
      if (mounted) setState(() => _streak = 0);
    }
  }

  Future<void> _loadLatestCheckIn(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('moodCheckIns')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final mood = data['mood'] as String?;
        final timestamp = data['date'] as Timestamp;
        if (mounted) {
          setState(() {
            _lastCheckInEmoji = _getMoodEmoji(mood);
            _lastCheckInDate = timestamp.toDate();
          });
        }
      }
    } catch (e) {
      print('Error loading latest check-in: $e');
    }
  }

  String _getMoodEmoji(String? mood) {
    const moodEmojis = {
      'sad': '😢',
      'stressed': '😰',
      'angry': '😠',
      'neutral': '😐',
      'calm': '😌',
      'happy': '😊',
    };
    return moodEmojis[mood?.toLowerCase()] ?? '😐';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'user@example.com';
    final theme = Theme.of(context);
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final isWeb = ResponsiveUtils.isWeb(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 1200 : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: padding, vertical: padding * 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, displayName, email),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                  _buildSectionTitle(context, 'Weekly Study Time (Hours)'),
                  SizedBox(height: padding * 0.75),
                  _buildWeeklyStudyChart(context),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                  _buildSectionTitle(context, 'Mood History'),
                  SizedBox(height: padding * 0.75),
                  _buildMoodChart(context),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                  _buildSectionTitle(context, 'Mood Streak & Monthly Heat Map'),
                  SizedBox(height: padding * 0.75),
                  _buildStreakAndHeatMap(context),
                  SizedBox(height: ResponsiveUtils.getSectionSpacing(context)),
                  _buildSectionTitle(context, 'Task Completion'),
                  SizedBox(height: padding * 0.75),
                  _buildTaskCompletionChart(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String email) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final avatarRadius = iconSize * 0.9;

    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.5),
              backgroundImage: _getAvatarImage(user?.photoURL),
              child: user?.photoURL == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: avatarRadius * 0.9,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _showAvatarOptions,
                child: Container(
                  padding: EdgeInsets.all(padding * 0.25),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: _uploadingAvatar
                      ? SizedBox(
                          width: iconSize * 0.4,
                          height: iconSize * 0.4,
                          child: const CircularProgressIndicator(
                            strokeWidth: 1,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt,
                          size: iconSize * 0.4,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: padding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: ResponsiveUtils.getTitleFontSize(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_updatingName) SizedBox(width: padding * 0.5),
                  if (_updatingName)
                    SizedBox(
                      width: iconSize * 0.4,
                      height: iconSize * 0.4,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(
                  height: ResponsiveUtils.getColumnSpacing(context) * 0.25),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.getBodyFontSize(context) * 0.85,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _showEditNameDialog,
          icon: Icon(Icons.edit_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          tooltip: 'Edit Display Name',
        ),
      ],
    );
  }

  Future<void> _showEditNameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName ?? '');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Display Name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) {
                  Navigator.pop(ctx);
                  _submitNameChange(controller);
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _submitNameChange(controller);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(scale: anim1, child: child);
      },
    );
  }

  Future<void> _submitNameChange(TextEditingController controller) async {
    final newName = controller.text.trim();
    if (newName.isEmpty) {
      await showFloatingBottomDialog(
        context,
        message: 'Name cannot be empty',
        type: AppMessageType.warning,
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await showFloatingBottomDialog(
        context,
        message: 'Not signed in',
        type: AppMessageType.error,
      );
      return;
    }
    try {
      if (!mounted) return;
      setState(() => _updatingName = true);
      await user.updateDisplayName(newName);
      await user.reload();
      if (!mounted) return; // widget may have been disposed while awaiting
      setState(() => _updatingName = false);
      await showFloatingBottomDialog(
        context,
        message: 'Name updated to "$newName"',
        type: AppMessageType.success,
      );
    } catch (e) {
      if (!mounted) return; // avoid setState after dispose
      setState(() => _updatingName = false);
      await showFloatingBottomDialog(
        context,
        message: 'Failed to update name: $e',
        type: AppMessageType.error,
      );
    }
  }

  Future<void> _showAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            if (FirebaseAuth.instance.currentUser?.photoURL != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      print('Starting image pick from $source');

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      print('Image picked: ${pickedFile.path}');
      setState(() => _uploadingAvatar = true);

      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('User authenticated: ${user.uid}');

      try {
        // Try Firebase Storage first
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${user.uid}.jpg');

        print('Storage reference created: ${storageRef.fullPath}');

        // Upload file
        print('Starting file upload to Firebase Storage...');
        final uploadTask = storageRef.putFile(File(pickedFile.path));

        await uploadTask;
        print('File uploaded to Firebase Storage successfully');

        // Get download URL
        final downloadURL = await storageRef.getDownloadURL();
        print('Download URL obtained: $downloadURL');

        // Update user profile
        await user.updatePhotoURL(downloadURL);
        await user.reload();
        print('User profile updated with Firebase Storage URL');

        if (mounted) {
          setState(() => _uploadingAvatar = false);
          await showFloatingBottomDialog(
            context,
            message: 'Avatar updated successfully via Firebase Storage!',
            type: AppMessageType.success,
          );
        }
      } catch (storageError) {
        print('Firebase Storage error: $storageError');
        print('Falling back to base64 storage in Firestore...');

        // Fallback: Convert to base64 and store in Firestore
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        // Store in Firestore user document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'avatar': base64String,
          'avatarUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update user profile with a placeholder
        await user.updatePhotoURL(base64String);
        await user.reload();

        print('Avatar stored in Firestore as base64');

        if (mounted) {
          setState(() => _uploadingAvatar = false);
          await showFloatingBottomDialog(
            context,
            message:
                'Avatar saved locally! (Enable Firebase Storage for cloud sync)',
            type: AppMessageType.warning,
          );
        }
      }
    } catch (e) {
      print('Avatar upload error: $e');
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        await showFloatingBottomDialog(
          context,
          message: 'Failed to upload avatar: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  Future<void> _removeAvatar() async {
    try {
      setState(() => _uploadingAvatar = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await user.updatePhotoURL(null);
      await user.reload();

      // Optionally delete from storage
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${user.uid}.jpg');
        await storageRef.delete();
      } catch (e) {
        // Ignore if file doesn't exist
      }

      if (mounted) {
        setState(() => _uploadingAvatar = false);
        await showFloatingBottomDialog(
          context,
          message: 'Avatar removed successfully!',
          type: AppMessageType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        await showFloatingBottomDialog(
          context,
          message: 'Failed to remove avatar: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
            fontWeight: FontWeight.w600,
          ),
    );
  }

  // Weekly Study Time Line Chart (Mon-Sun)
  Widget _buildWeeklyStudyChart(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Sign in to view study stats');
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
          // Explicit order to make intent clear; requires composite index on (userId ASC, start ASC)
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
        final maxY = (dailyHours.reduce((a, b) => a > b ? a : b) + 0.5)
            .clamp(1, 24); // simple headroom
        final spots = <FlSpot>[
          for (int i = 0; i < 7; i++) FlSpot(i.toDouble(), dailyHours[i])
        ];
        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        final theme = Theme.of(context);
        final lineColor = theme.colorScheme.primary;
        final chartHeight = ResponsiveUtils.isWeb(context)
            ? 320.0
            : (ResponsiveUtils.isTablet(context) ? 280.0 : 250.0);
        final padding = ResponsiveUtils.getCardPadding(context);
        final borderRadius = ResponsiveUtils.getCardBorderRadius(context);
        final smallFontSize = ResponsiveUtils.getSmallFontSize(context);

        return SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius.toDouble())),
            child: Padding(
              padding: EdgeInsets.all(padding.toDouble()),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY.toDouble(),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: (maxY / 4).clamp(0.5, double.infinity),
                  ),
                  borderData: FlBorderData(show: false),
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
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx > 6) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[idx],
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: smallFontSize * 0.85,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        reservedSize: 45,
                        showTitles: true,
                        interval: (maxY / 4).clamp(0.5, double.infinity),
                        getTitlesWidget: (value, meta) => Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toStringAsFixed(1)}h',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: smallFontSize * 0.75,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: lineColor,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: lineColor.withValues(alpha: 0.18),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withValues(alpha: 0.25),
                            lineColor.withValues(alpha: 0.02)
                          ],
                        ),
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

  // Enhanced Mood Analytics with multiple time periods
  Widget _buildMoodChart(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Text('Sign in to view mood analytics');

    final padding = ResponsiveUtils.getCardPadding(context);
    final borderRadius = ResponsiveUtils.getCardBorderRadius(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.toDouble())),
        child: Padding(
          padding: EdgeInsets.all(padding.toDouble()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mood Analytics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize * 0.95,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtils.getColumnSpacing(context) * 0.5),
                  _buildPeriodSelector(context),
                ],
              ),
              SizedBox(height: ResponsiveUtils.getColumnSpacing(context)),
              _buildChartForPeriod(context, user.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final smallFontSize = ResponsiveUtils.getSmallFontSize(context);
    final iconSize = ResponsiveUtils.getIconSize(context) * 0.4;

    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'week',
          label: Text('Week', style: TextStyle(fontSize: smallFontSize * 0.75)),
          icon: Icon(Icons.view_week, size: iconSize),
        ),
        ButtonSegment(
          value: 'month',
          label:
              Text('Month', style: TextStyle(fontSize: smallFontSize * 0.75)),
          icon: Icon(Icons.calendar_view_month, size: iconSize),
        ),
        ButtonSegment(
          value: 'year',
          label: Text('Year', style: TextStyle(fontSize: smallFontSize * 0.75)),
          icon: Icon(Icons.calendar_today, size: iconSize),
        ),
      ],
      selected: {_chartPeriod},
      onSelectionChanged: (Set<String> selection) {
        setState(() {
          _chartPeriod = selection.first;
        });
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        selectedForegroundColor:
            Theme.of(context).colorScheme.onPrimaryContainer,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getColumnSpacing(context) * 0.5,
          vertical: ResponsiveUtils.getColumnSpacing(context) * 0.25,
        ),
        minimumSize: Size(50, ResponsiveUtils.getButtonHeight(context) * 0.5),
      ),
    );
  }

  Widget _buildChartForPeriod(BuildContext context, String userId) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    int dataPoints;
    String Function(DateTime, int) labelFormatter;

    switch (_chartPeriod) {
      case 'week':
        startDate = now.subtract(
            Duration(days: now.weekday - 1)); // Start of week (Monday)
        endDate = startDate.add(const Duration(days: 7));
        dataPoints = 7;
        labelFormatter = (date, _) =>
            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
        dataPoints = DateTime(now.year, now.month + 1, 0).day;
        labelFormatter = (date, idx) =>
            idx % 5 == 0 || idx == dataPoints - 1 ? '${date.day}' : '';
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
        dataPoints = 12;
        labelFormatter = (date, _) => [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec'
            ][date.month - 1];
        break;
      default:
        return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('moodCheckIns')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 320, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 8),
                  const Text('Unable to load mood data'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        return _buildEnhancedChart(
            context, docs, startDate, endDate, dataPoints, labelFormatter);
      },
    );
  }

  Widget _buildEnhancedChart(
      BuildContext context,
      List<QueryDocumentSnapshot> docs,
      DateTime startDate,
      DateTime endDate,
      int dataPoints,
      String Function(DateTime, int) labelFormatter) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Mood to numeric scale (1–6) for plotting
    const moodOrder = ['sad', 'stressed', 'angry', 'neutral', 'calm', 'happy'];
    int moodValue(String? mood) {
      if (mood == null) return 0;
      final idx = moodOrder.indexOf(mood.toLowerCase());
      return idx == -1 ? 3 : idx + 1; // default to neutral if unknown
    }

    String labelFor(int v) {
      if (v <= 0 || v > moodOrder.length) return '';
      return moodOrder[v - 1].substring(0, 1).toUpperCase();
    }

    // Process mood data based on period
    final moodData =
        <int, List<int>>{}; // index -> list of mood values for that period
    final checkInCounts =
        <int, int>{}; // index -> number of check-ins for that period
    final dailyData = <int, Map<String, int>>{}; // index -> {mood: count}

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['date'] as Timestamp;
      final date = timestamp.toDate();
      final mood = data['mood'] as String?;
      final moodVal = moodValue(mood);

      int index;
      if (_chartPeriod == 'week') {
        index = date.difference(startDate).inDays;
      } else if (_chartPeriod == 'month') {
        index = date.day - 1;
      } else {
        // year
        index = date.month - 1;
      }

      if (index >= 0 && index < dataPoints) {
        moodData.putIfAbsent(index, () => []).add(moodVal);
        checkInCounts[index] = (checkInCounts[index] ?? 0) + 1;

        // Track individual mood counts
        dailyData.putIfAbsent(index, () => {});
        final moodName = mood?.toLowerCase() ?? 'neutral';
        dailyData[index]![moodName] = (dailyData[index]![moodName] ?? 0) + 1;
      }
    }

    // Calculate average mood and prepare chart data
    final spots = <FlSpot>[];
    final barData = <BarChartGroupData>[];
    double maxCheckIns = 0;

    for (int i = 0; i < dataPoints; i++) {
      final moods = moodData[i] ?? [];
      final checkInCount = checkInCounts[i] ?? 0;

      if (moods.isNotEmpty) {
        final avgMood = moods.reduce((a, b) => a + b) / moods.length;
        spots.add(FlSpot(i.toDouble(), avgMood));
      }

      barData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: checkInCount.toDouble(),
              color: checkInCount > 0
                  ? primary.withValues(alpha: 0.7)
                  : Colors.grey.withValues(alpha: 0.3),
              width: _chartPeriod == 'year'
                  ? 18
                  : (_chartPeriod == 'month' ? 5 : 10),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        ),
      );

      if (checkInCount > maxCheckIns) maxCheckIns = checkInCount.toDouble();
    }

    final chartHeight = ResponsiveUtils.isWeb(context)
        ? 480.0
        : (ResponsiveUtils.isTablet(context) ? 420.0 : 380.0);
    final padding = ResponsiveUtils.getColumnSpacing(context);

    return Container(
      height: chartHeight,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padding * 0.25),
      child: Column(
        children: [
          // Summary stats row with last check-in emoji
          _buildStatsRow(context, docs, moodData, checkInCounts),
          SizedBox(height: padding),

          // Mood trend line chart
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Average Mood Trend',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (_lastCheckInEmoji != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_lastCheckInEmoji!,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              'Latest',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (dataPoints - 1).toDouble(),
                        minY: 1,
                        maxY: 6,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 1,
                          verticalInterval: _chartPeriod == 'year'
                              ? 2
                              : (_chartPeriod == 'month' ? 5 : 1),
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: Colors.grey.withValues(alpha: 0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: _chartPeriod == 'month' ? 28 : 35,
                              interval: _chartPeriod == 'year'
                                  ? 1
                                  : (_chartPeriod == 'month' ? 6 : 1),
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= dataPoints) {
                                  return const SizedBox.shrink();
                                }

                                DateTime dateForLabel;
                                if (_chartPeriod == 'week') {
                                  dateForLabel =
                                      startDate.add(Duration(days: idx));
                                } else if (_chartPeriod == 'month') {
                                  dateForLabel = DateTime(
                                      startDate.year, startDate.month, idx + 1);
                                } else {
                                  dateForLabel =
                                      DateTime(startDate.year, idx + 1, 1);
                                }

                                final label = labelFormatter(dateForLabel, idx);
                                if (label.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  width: _chartPeriod == 'month'
                                      ? 20
                                      : (_chartPeriod == 'year' ? 28 : 30),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    label,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: primary,
                                      fontSize: _chartPeriod == 'month'
                                          ? 8
                                          : (_chartPeriod == 'year' ? 10 : 11),
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              reservedSize: 40,
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Container(
                                  width: 35,
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    labelFor(value.toInt()),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: primary,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: spots.isEmpty
                            ? []
                            : [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: primary,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 5,
                                        color: primary,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        primary.withValues(alpha: 0.3),
                                        primary.withValues(alpha: 0.05),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // Check-in frequency bar chart
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check-in Frequency',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: (maxCheckIns + 1)
                            .clamp(1, double.infinity), // Ensure positive maxY
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: maxCheckIns > 5
                              ? (maxCheckIns / 3).ceil().toDouble()
                              : 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              reservedSize: 40,
                              showTitles: true,
                              interval: maxCheckIns > 10
                                  ? (maxCheckIns / 5).ceil().toDouble()
                                  : 1,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 || value.toInt() != value) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  width: 35,
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(fontSize: 10),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: barData,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} check-ins',
                                theme.textTheme.labelSmall!
                                    .copyWith(color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, List<QueryDocumentSnapshot> docs,
      Map<int, List<int>> moodData, Map<int, int> checkInCounts) {
    final theme = Theme.of(context);

    // Calculate stats
    final totalCheckIns = docs.length;
    final daysWithData = moodData.keys.length;
    final allMoods = moodData.values.expand((x) => x).toList();
    final avgMood = allMoods.isEmpty
        ? 0.0
        : allMoods.reduce((a, b) => a + b) / allMoods.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, 'Total Check-ins',
              totalCheckIns.toString(), Icons.check_circle_outline),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildStatCard(context, 'Active Days', daysWithData.toString(),
              Icons.calendar_today),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildStatCard(
            context,
            'Latest Mood',
            _lastCheckInEmoji != null
                ? '$_lastCheckInEmoji ${_getLastMoodName()}'
                : 'No data',
            Icons.update,
            color: _getMoodColor(avgMood.round(), theme),
          ),
        ),
      ],
    );
  }

  String _getLastMoodName() {
    if (_lastCheckInDate == null) return '';
    final now = DateTime.now();
    final difference = now.difference(_lastCheckInDate!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon,
      {Color? color}) {
    final theme = Theme.of(context);
    return Container(
      height: 85, // Fixed height for consistent sizing
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(int moodValue, ThemeData theme) {
    const colors = [
      Colors.red, // sad
      Colors.orange, // stressed
      Colors.deepOrange, // angry
      Colors.grey, // neutral
      Colors.green, // calm
      Colors.lightGreen, // happy
    ];

    if (moodValue >= 1 && moodValue <= 6) {
      return colors[moodValue - 1];
    }
    return theme.colorScheme.primary;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildStreakAndHeatMap(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Text('Sign in to view mood heat map');
    final theme = Theme.of(context);
    final month = _selectedMonth;
    final firstWeekday =
        DateTime(month.year, month.month, 1).weekday; // 1=Mon..7=Sun
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((firstWeekday - 1) + daysInMonth);
    final rowCount = (totalCells / 7).ceil();
    const moods = ['sad', 'stressed', 'angry', 'neutral', 'calm', 'happy'];
    int moodIndex(String m) {
      final i = moods.indexOf(m.toLowerCase());
      return i < 0 ? 0 : i;
    }

    Color moodColor(String m) {
      final i = moodIndex(m);
      final base = theme.colorScheme.primary;
      final steps = [0.15, 0.30, 0.45, 0.60, 0.75, 0.9];
      return base.withValues(alpha: steps[i]);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
          horizontal: 2), // Add margin to prevent overflow
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding:
              const EdgeInsets.all(16.0), // Reduced padding to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mood Heat Map',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department,
                                      size: 16,
                                      color:
                                          theme.colorScheme.onPrimaryContainer),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_streak ?? 0} day streak',
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Previous Month',
                        onPressed: () => setState(() {
                          _selectedMonth =
                              DateTime(month.year, month.month - 1, 1);
                        }),
                        icon: const Icon(Icons.chevron_left, size: 20),
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_getMonthName(month.month)} ${month.year}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next Month',
                        onPressed: () => setState(() {
                          _selectedMonth =
                              DateTime(month.year, month.month + 1, 1);
                        }),
                        icon: const Icon(Icons.chevron_right, size: 20),
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<MoodCheckIn>>(
                stream: _moodService.monthMoods(user.uid, month),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()));
                  }
                  final list = snapshot.data!;
                  final byDay = <int, List<String>>{};
                  for (final m in list) {
                    final d = m.date.day;
                    byDay.putIfAbsent(d, () => []).add(m.mood);
                  }
                  double avgMoodValue(List<String> moodsList) {
                    if (moodsList.isEmpty) return 0;
                    final values =
                        moodsList.map((e) => moodIndex(e) + 1).toList();
                    return values.reduce((a, b) => a + b) / values.length;
                  }

                  Color blendedColor(List<String> moodsList) {
                    if (moodsList.isEmpty) {
                      return theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.25);
                    }
                    final avg = avgMoodValue(moodsList); // 1..6
                    final ratio = (avg - 1) / 5; // 0..1
                    final happy = theme.colorScheme.primary;
                    final sad = theme.colorScheme.error.withValues(alpha: 0.85);
                    final lerpedColor = Color.lerp(sad, happy, ratio);
                    return (lerpedColor ?? happy).withValues(alpha: 0.8);
                  }

                  return Column(
                    children: [
                      // Weekday labels with better spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2), // Reduced padding to match grid
                        child: Row(
                          children: [
                            for (final day in [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ])
                              Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal:
                                2), // Reduced padding to prevent overflow
                        child: SizedBox(
                          height: rowCount * 38,
                          child: Column(
                            children: List.generate(rowCount, (row) {
                              return Expanded(
                                child: Row(
                                  children: List.generate(7, (col) {
                                    final cellIndex = row * 7 + col;
                                    final dayNumber =
                                        cellIndex - (firstWeekday - 1) + 1;
                                    if (dayNumber < 1 ||
                                        dayNumber > daysInMonth) {
                                      return Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.all(1.5),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      );
                                    }
                                    final moodsList = byDay[dayNumber] ?? [];
                                    final cellColor = blendedColor(moodsList);
                                    return Expanded(
                                      child: Tooltip(
                                        message: moodsList.isEmpty
                                            ? 'No check-ins on day $dayNumber'
                                            : 'Day $dayNumber: ${moodsList.length} check-in(s) (${moodsList.join(', ')})',
                                        child: Container(
                                          margin: const EdgeInsets.all(1.5),
                                          decoration: BoxDecoration(
                                            color: cellColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: moodsList.isNotEmpty
                                                ? Border.all(
                                                    color: theme
                                                        .colorScheme.outline
                                                        .withValues(alpha: 0.3),
                                                    width: 0.5,
                                                  )
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              dayNumber.toString(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: moodsList.isEmpty
                                                    ? theme
                                                        .colorScheme.onSurface
                                                        .withValues(alpha: 0.6)
                                                    : Colors.white.withValues(
                                                        alpha: 0.95),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2), // Reduced padding to match grid
                        child: Row(
                          children: [
                            Text('Activity:',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                )),
                            const SizedBox(width: 12),
                            Text('Less',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                )),
                            const SizedBox(width: 6),
                            ...List.generate(
                                5,
                                (i) => Container(
                                      width: 14,
                                      height: 14,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(
                                                alpha: 0.2 + (i * 0.16)),
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.2),
                                          width: 0.5,
                                        ),
                                      ),
                                    )),
                            const SizedBox(width: 6),
                            Text('More',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2), // Reduced padding to match grid
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 6, // Reduced spacing to fit better
                          runSpacing: 4, // Reduced spacing
                          children: [
                            for (final m in moods)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: moodColor(m).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          moodColor(m).withValues(alpha: 0.4),
                                      width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: moodColor(m),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.capitalize(),
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder widget for the Task Completion Chart
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
        // New distinct remaining color: derive from secondary to clearly differ from completed (primary)
        // Keep translucency adaptive so it doesn't overpower the completed segment.
        final secondaryBase = theme.colorScheme.secondary;
        final remainingColor = theme.brightness == Brightness.dark
            ? secondaryBase.withValues(alpha: 0.32)
            : secondaryBase.withValues(alpha: 0.26);
        final completedPctStr =
            total == 0 ? '0%' : '${completionPct.toStringAsFixed(0)}%';
        final remainingPctStr =
            total == 0 ? '—' : '${(100 - completionPct).toStringAsFixed(0)}%';

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
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pieSize =
                    (constraints.maxWidth * 0.38).clamp(110.0, 150.0);
                final outerRadius = pieSize * 0.5; // displayed radius
                final holeRadius = outerRadius * 0.72; // donut thickness
                final pctStr = completionPct.toStringAsFixed(0);
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
                              )
                            ],
                          )
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
                            value: '$completed • $completedPctStr',
                            emphasize: true,
                          ),
                          const SizedBox(height: 6),
                          _legendEntry(
                            color: remainingColor,
                            label: 'Remaining',
                            value: '$remaining • $remainingPctStr',
                          ),
                          const SizedBox(height: 10),
                          // Mini progress bar
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
                              if (total > 0)
                                Text(
                                  completedPctStr,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: completedColor,
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
    final textStyleBase = theme.textTheme.labelMedium;
    final labelStyle = (emphasize
            ? textStyleBase?.copyWith(fontWeight: FontWeight.w600)
            : textStyleBase)
        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.78));
    final valueStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      letterSpacing: 0.2,
    );
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: label, style: labelStyle),
                TextSpan(text: '  '),
                TextSpan(text: value, style: valueStyle),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
