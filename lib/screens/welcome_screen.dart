// lib/screens/welcome_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_signup_screen.dart'; // Import for navigation

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Soft blue to mint green gradient background (top to bottom)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [softBlue, Color(0xFF0E97DB)],
            stops: [0.3, 0.9],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              const Spacer(flex: 2),

              // App Logo
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.book_rounded,
                  size: 50,
                  color: mintGreen,
                ),
              ),
              const SizedBox(height: 16),

              // App Title
              Text(
                'Adaptive Student\nPlanner & Journal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: mutedNeutralDark,
                ),
              ),
              const SizedBox(height: 40),
                // Calming Illustration
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/illustration.png',
                          fit: BoxFit.cover,
                        ),
                        
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

              // Tagline
              Text(
                'Balance your tasks. Balance your mind.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: mutedNeutralDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(flex: 1),

              // Buttons
              Column(
                children: [
                  // Get Started (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginSignupScreen()));
                      },
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login (Outlined)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginSignupScreen(initialTabIndex: 0)));
                      },
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}