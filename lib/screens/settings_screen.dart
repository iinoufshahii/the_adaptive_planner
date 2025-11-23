/// Settings screen for user preferences, theme toggle, notifications, and account management.
/// Provides logout with confirmation dialog, theme switching via Provider pattern.

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../dialogs/app_dialogs.dart';
import '../providers/theme_provider.dart';
import '../Service/category_service.dart';
import '../Theme/App_Theme.dart';
import '../Widgets/Responsive_widget.dart';
import 'category_management_screen.dart';
import 'notification_settings_screen.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoggingOut = false;
  bool _uploadingAvatar = false;
  bool _updatingName = false;
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _imagePicker = ImagePicker();

  // --- Function to handle user logout ---
  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // Proactively navigate to WelcomeScreen clearing the stack.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      await showFloatingBottomDialog(
        context,
        message: 'Logout failed: $e',
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  // --- Show confirmation dialog before logging out ---
  void _confirmLogout() async {
    await showConfirmationDialog(
      context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to log out?',
      confirmButtonLabel: 'Logout',
      cancelButtonLabel: 'Cancel',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        await _logout();
      },
    );
  }

  /// Show About App dialog with app information
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Adaptive Planner'),
        content: const Text(
          'Adaptive Planner & Journal v1.0.0\n\n'
          'Developed with ❤️ using Flutter & Firebase\n\n'
          'A smart task planning and productivity app designed to adapt to your mood and energy levels.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show Help & Support dialog with contact information
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? Contact us at:\n\n'
          'Email: support@adaptiveplanner.com\n\n'
          'We\'re here to help you make the most of Adaptive Planner & Journal!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Function to show the delete account confirmation dialog ---
  void _showDeleteAccountDialog() {
    final deleteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'This action is irreversible. All your data will be permanently deleted. Please type "DELETE" to confirm.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: deleteController,
                  decoration: const InputDecoration(labelText: 'Type "DELETE"'),
                  validator: (value) {
                    if (value != 'DELETE') {
                      return 'Please type "DELETE" to confirm.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: deleteController,
              builder: (context, value, child) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: value.text == 'DELETE'
                      ? () {
                          if (formKey.currentState!.validate()) {
                            Navigator.of(context).pop();
                            _deleteUserAccount();
                          }
                        }
                      : null, // Button is disabled if text is not "DELETE"
                  child: const Text('Delete'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Handles account deletion with complete data cleanup.
  ///
  /// Performs two-step deletion:
  /// 1. Deletes all user data from Firestore (tasks, moods, journals, etc.)
  /// 2. Deletes Firebase Auth account
  ///
  /// Shows success message and navigates to welcome page on completion.
  /// Handles "requires-recent-login" error with helpful message.
  // --- Function to handle the actual account deletion ---
  Future<void> _deleteUserAccount() async {
    final buildContext = context;
    final user = FirebaseAuth.instance.currentUser;

    try {
      // Step 1: Delete all user data from Firestore before deleting account
      if (user != null) {
        await _deleteUserData(user.uid);
      }

      // Step 2: Delete Firebase Auth account
      await FirebaseAuth.instance.currentUser?.delete();

      if (mounted) {
        await showFloatingBottomDialog(
          buildContext,
          message: 'Account and all data deleted successfully.',
          type: AppMessageType.success,
        );
        // Navigate to WelcomeScreen after account deletion
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'requires-recent-login') {
          await showFloatingBottomDialog(
            buildContext,
            message:
                'This operation requires recent authentication. Please log out and log back in before trying again.',
            type: AppMessageType.error,
          );
        } else {
          await showFloatingBottomDialog(
            buildContext,
            message: 'Error deleting account: ${e.message}',
            type: AppMessageType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showFloatingBottomDialog(
          buildContext,
          message: 'Unexpected error: $e',
          type: AppMessageType.error,
        );
      }
    }
  }

  /// Deletes all user data from Firestore collections.
  /// This includes tasks, mood check-ins, journals, focus sessions, categories, and user preferences.
  Future<void> _deleteUserData(String userId) async {
    final db = FirebaseFirestore.instance;

    try {
      // Delete all user tasks
      final tasksQuery =
          await db.collection('tasks').where('userId', isEqualTo: userId).get();
      for (var doc in tasksQuery.docs) {
        await doc.reference.delete();
      }

      // Delete all user mood check-ins
      final moodQuery = await db
          .collection('moodCheckIns')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in moodQuery.docs) {
        await doc.reference.delete();
      }

      // Delete all user journal entries
      final journalQuery = await db
          .collection('journals')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in journalQuery.docs) {
        await doc.reference.delete();
      }

      // Delete all user focus sessions
      final focusQuery = await db
          .collection('focusSessions')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in focusQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user-specific subcollections in users document
      final userDoc = db.collection('users').doc(userId);

      // Delete all focus preferences
      final prefsSnapshot = await userDoc.collection('focusPrefs').get();
      for (var doc in prefsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all categories (if stored under user document)
      final categoriesSnapshot = await userDoc.collection('categories').get();
      for (var doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the user document itself
      await userDoc.delete();

      debugPrint('All user data deleted successfully for user: $userId');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      rethrow; // Re-throw so it's caught by the caller
    }
  }

  // --- Navigate to category management screen ---
  void _showCategoryManagementDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryManagementScreen(
          categoryService: _categoryService,
        ),
      ),
    );
  }

  /// Get avatar image from URL (handles both Firebase URLs and base64)
  ImageProvider? _getAvatarImage(String? photoURL) {
    if (photoURL == null || photoURL == 'firestore:avatar') return null;

    if (photoURL.startsWith('data:image')) {
      // Handle base64 images
      try {
        final base64String = photoURL.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return null;
      }
    } else {
      // Handle regular URLs
      return NetworkImage(photoURL);
    }
  }

  /// Build avatar widget that handles async Firestore loading
  Widget _buildAvatarWidget(User user, double avatarRadius, ThemeData theme) {
    if (user.photoURL == 'firestore:avatar') {
      // Load avatar from Firestore asynchronously
      return FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data?.exists == true) {
            final base64String = snapshot.data!['avatar'] as String?;
            if (base64String != null) {
              try {
                final bytes = base64Decode(base64String);
                return CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: MemoryImage(bytes),
                );
              } catch (e) {
                debugPrint('Error decoding avatar: $e');
              }
            }
          }
          // Fallback to default avatar
          return CircleAvatar(
            radius: avatarRadius,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
            child: Icon(
              Icons.person,
              size: avatarRadius * 1.5,
              color: theme.colorScheme.primary,
            ),
          );
        },
      );
    } else {
      // Regular avatar (URL or none)
      return CircleAvatar(
        radius: avatarRadius,
        backgroundImage: _getAvatarImage(user.photoURL),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        child: user.photoURL == null
            ? Icon(
                Icons.person,
                size: avatarRadius * 1.5,
                color: theme.colorScheme.primary,
              )
            : null,
      );
    }
  }

  /// Show avatar options (camera/gallery/remove)
  Future<void> _showAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            if (FirebaseAuth.instance.currentUser?.photoURL != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove avatar',
                    style: TextStyle(color: Colors.red)),
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

  /// Pick image from camera/gallery and upload to Firebase
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      debugPrint('Starting image pick from $source');

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        debugPrint('No image selected');
        return;
      }

      debugPrint('Image picked: ${pickedFile.path}');
      setState(() => _uploadingAvatar = true);

      // Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('User authenticated: ${user.uid}');

      try {
        // Try Firebase Storage first
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${user.uid}.jpg');

        debugPrint('Storage reference created: ${storageRef.fullPath}');

        // Upload file
        debugPrint('Starting file upload to Firebase Storage...');
        final uploadTask = storageRef.putFile(File(pickedFile.path));

        await uploadTask;
        debugPrint('File uploaded to Firebase Storage successfully');

        // Get download URL
        final downloadURL = await storageRef.getDownloadURL();
        debugPrint('Download URL obtained: $downloadURL');

        // Update user profile
        await user.updatePhotoURL(downloadURL);
        await user.reload();
        debugPrint('User profile updated with Firebase Storage URL');('User profile updated with Firebase Storage URL');

        if (mounted) {
          setState(() => _uploadingAvatar = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
        }
      } catch (storageError) {
        debugPrint('Firebase Storage error: $storageError');
        debugPrint('Falling back to Firestore storage...');

        // Fallback: Convert to base64 and store in Firestore
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);

        // Store base64 in Firestore user document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {
            'avatar': base64String,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Set a marker in photoURL to indicate avatar is in Firestore
        await user.updatePhotoURL('firestore:avatar');
        await user.reload();

        debugPrint('Avatar stored in Firestore');

        if (mounted) {
          setState(() => _uploadingAvatar = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Remove user avatar
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

  /// Show edit name dialog
  Future<void> _showEditNameDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName ?? '');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  decoration: InputDecoration(
                    hintText: 'Enter your display name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updatingName
                          ? null
                          : () async {
                              final newName = controller.text.trim();
                              if (newName.isEmpty) {
                                await showFloatingBottomDialog(
                                  context,
                                  message: 'Name cannot be empty',
                                  type: AppMessageType.warning,
                                );
                                return;
                              }
                              Navigator.pop(ctx);
                              await _submitNameChange(newName);
                            },
                      child: _updatingName
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(scale: anim1, child: child);
      },
    );
  }

  /// Submit name change to Firebase
  Future<void> _submitNameChange(String newName) async {
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
      if (!mounted) return;
      setState(() => _updatingName = false);
      await showFloatingBottomDialog(
        context,
        message: 'Name updated to "$newName"',
        type: AppMessageType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updatingName = false);
      await showFloatingBottomDialog(
        context,
        message: 'Failed to update name: $e',
        type: AppMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final padding = ResponsiveUtils.getDefaultPadding(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context);
    final bodyFontSize = ResponsiveUtils.getBodyFontSize(context);
    final isWeb = ResponsiveUtils.isWeb(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWeb ? 800 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.all(padding.toDouble()),
            children: [
              // Profile Header Section
              _buildProfileHeader(user, bodyFontSize, padding),
              const SizedBox(height: 20),

              // Preferences Section
              _buildSectionTitle('Preferences'),
              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: bodyFontSize),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                },
                secondary: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  size: ResponsiveUtils.getIconSize(context),
                ),
                activeThumbColor: mintGreen,
              ),
              const Divider(height: 40),

              // Task Management Section
              _buildSectionTitle('Task Management'),
              ListTile(
                leading: Icon(Icons.notifications_outlined,
                    size: ResponsiveUtils.getIconSize(context)),
                title: Text(
                  'Notification Settings',
                  style: TextStyle(fontSize: bodyFontSize),
                ),
                subtitle: const Text('Configure reminders and notifications'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.category_outlined,
                    size: ResponsiveUtils.getIconSize(context)),
                title: Text(
                  'Manage Categories',
                  style: TextStyle(fontSize: bodyFontSize),
                ),
                subtitle: const Text('Add, edit, or delete task categories'),
                onTap: _showCategoryManagementDialog,
              ),
              const Divider(height: 40),

              // App Information Section
              _buildSectionTitle('App Information'),
              ListTile(
                leading: Icon(Icons.info_outline,
                    size: ResponsiveUtils.getIconSize(context)),
                title: Text(
                  'About App',
                  style: TextStyle(fontSize: bodyFontSize),
                ),
                subtitle: const Text('Version 1.0.0'),
                onTap: _showAboutDialog,
              ),
              ListTile(
                leading: Icon(Icons.help_outline,
                    size: ResponsiveUtils.getIconSize(context)),
                title: Text(
                  'Help & Support',
                  style: TextStyle(fontSize: bodyFontSize),
                ),
                onTap: _showHelpDialog,
              ),
              const Divider(height: 40),

              // Account Section
              _buildSectionTitle('Account'),
              ListTile(
                leading: Icon(Icons.logout,
                    size: ResponsiveUtils.getIconSize(context)),
                title: Text(
                  'Logout',
                  style: TextStyle(fontSize: bodyFontSize),
                ),
                onTap: _confirmLogout,
              ),
              ListTile(
                leading: Icon(Icons.delete_forever,
                    color: Colors.red.shade400,
                    size: ResponsiveUtils.getIconSize(context)),
                title: Text('Delete Account',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: bodyFontSize,
                    )),
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build profile header with avatar, name, and email
  Widget _buildProfileHeader(User? user, double bodyFontSize, double padding) {
    final theme = Theme.of(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    final avatarRadius = iconSize * 1.8;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        Container(
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
              Center(
                child: Column(
                  children: [
                    // Avatar Stack
                    Stack(
                      children: [
                        // Avatar Circle with Glow and Shadow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              // Glow effect
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 0),
                              ),
                              // Drop shadow
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildAvatarWidget(user, avatarRadius, theme),
                        ),
                        // Edit Avatar Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              iconSize: 18,
                              onPressed:
                                  _uploadingAvatar ? null : _showAvatarOptions,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: padding),

                    // Name and Email
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          user.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: bodyFontSize * 1.2,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 17, 173, 235),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: padding * 0.25),
                        Text(
                          user.email ?? 'user@example.com',
                          style: TextStyle(
                            fontSize: bodyFontSize * 0.9,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Edit Name Button (Top Left)
        Positioned(
          top: padding * 0.5,
          left: padding * 0.5,
          child: IconButton(
            onPressed: _showEditNameDialog,
            icon: Icon(
              Icons.edit_outlined,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            tooltip: 'Edit Display Name',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context)
              .textTheme
              .bodySmall
              ?.color
              ?.withValues(alpha: 0.6),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
