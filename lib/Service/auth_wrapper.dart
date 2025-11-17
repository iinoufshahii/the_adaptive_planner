/// Authentication wrapper widget that routes users based on login state.
///
/// Uses Firebase Auth state stream to determine whether to show:
/// - DashboardScreen: If user is authenticated
/// - WelcomeScreen: If user is not authenticated
///
/// Shows loading indicator while checking auth state.

import 'package:adaptive_planner/Screens/dashboard_screen.dart';
import 'package:adaptive_planner/Screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Widget that conditionally renders screens based on Firebase authentication state.
///
/// Listens to [FirebaseAuth.authStateChanges()] stream and routes to:
/// - Dashboard if user is logged in
/// - Welcome screen if user is logged out
/// - Loading spinner while checking state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Route authenticated users to dashboard
        if (snapshot.hasData) {
          return const DashboardScreen();
        }

        // Route unauthenticated users to welcome screen
        return const WelcomeScreen();
      },
    );
  }
}
