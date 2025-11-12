// lib/screens/settings_screen.dart

import 'package:adaptive_planner/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_planner/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoggingOut = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  // --- Show confirmation dialog before logging out ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _logout();
            },
            child: _isLoggingOut
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // --- Show About App dialog ---
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Adaptive Planner'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adaptive Planner', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 16),
            Text('An intelligent task management app that adapts to your mood and energy levels.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• AI-powered mood analysis'),
            Text('• Smart task prioritization'),
            Text('• Intelligent journaling'),
            Text('• Task breakdown assistance'),
            Text('• Focus sessions & Pomodoro timer'),
            SizedBox(height: 16),
            Text('Developed with ❤️ using Flutter & Firebase'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- Show Help & Support dialog ---
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Getting Started:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('1. Add your first task in the Dashboard'),
            Text('2. Write journal entries to track your mood'),
            Text('3. Let AI analyze your emotions and suggest task priorities'),
            Text('4. Use the Task Breakdown feature for complex projects'),
            SizedBox(height: 16),
            Text('Tips for Best Results:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Write honest, detailed journal entries'),
            Text('• Check in with your mood regularly'),
            Text('• Set realistic deadlines for tasks'),
            Text('• Use focus sessions to maintain productivity'),
            SizedBox(height: 16),
            Text('Need more help? Contact: support@adaptiveplanner.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
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

  // --- Function to handle the actual account deletion ---
  Future<void> _deleteUserAccount() async {
    final buildContext = context;
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      ScaffoldMessenger.of(buildContext).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          const SnackBar(
              content: Text(
                  'This operation is sensitive and requires recent authentication. Please log out and log back in before trying again.')),
        );
      } else {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Preferences'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() => _notificationsEnabled = value);
              // TODO: Add logic to subscribe/unsubscribe from Firebase Cloud Messaging topics
            },
            secondary: const Icon(Icons.notifications_outlined),
            activeThumbColor: mintGreen,
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
            secondary: Icon(themeProvider.isDarkMode
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined),
            activeThumbColor: mintGreen,
          ),
          const Divider(height: 40),
          _buildSectionTitle('App Information'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            subtitle: const Text('Version 1.0.0'),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: _showHelpDialog,
          ),
          const Divider(height: 40),
          _buildSectionTitle('Account'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _confirmLogout,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
            title: Text('Delete Account',
                style: TextStyle(color: Colors.red.shade400)),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
