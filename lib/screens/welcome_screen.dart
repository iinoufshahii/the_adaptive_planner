/// Onboarding/welcome screen with sequential animations for title, subtitle, buttons, and gradient.
/// Shows app intro with smooth fade-in and slide transitions before login redirect.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import '../Widgets/Responsive_widget.dart';
import 'login_signup_screen.dart'; // Import for navigation

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _illustrationController;
  late Animation<double> _illustrationScale;

  late AnimationController _titleController;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;

  late AnimationController _subtitleController;
  late Animation<double> _subtitleOpacity;

  late AnimationController _buttonsController;
  late Animation<double> _buttonsOpacity;

  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Illustration zoom out animation (starts big)
    _illustrationController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _illustrationScale = Tween<double>(begin: 2.0, end: 1.0).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeOut),
    );

    // Title fade and slide from top
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeIn),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    // Subtitle fade in
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Buttons fade-in animation
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeIn),
    );

    // Gradient breathing animation
    _gradientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );

    // Start animations sequentially
    _illustrationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _titleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _subtitleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _illustrationController.dispose();
    _subtitleController.dispose();
    _buttonsController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If user is logged in, show dashboard instead
        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.data != null) {
          return const DashboardScreen();
        }

        // Otherwise show welcome screen
        return Scaffold(
          body: AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomCenter,
                    radius: 1.2 +
                        _gradientAnimation.value * 0.3, // Breathing effect
                    colors: [
                      Color.fromARGB(255, 179, 232, 252), // Pale Aqua
                      Color.fromARGB(255, 150, 212, 226), // Soft Sky Blue
                      Color(0xFF66B2D6), // Dreamy Blue
                      Color.fromARGB(255, 70, 148, 176), // Deep Aqua
                    ],
                    stops: [
                      0.0,
                      0.8 + _gradientAnimation.value * 0.1,
                      0.10 + _gradientAnimation.value * 0.1,
                      1.0,
                    ],
                  ),
                ),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  const Spacer(flex: 2),

                  // Animated App Title
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: Text(
                        'Adaptive Student\nPlanner & Journal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color:
                              Color.fromARGB(255, 255, 255, 255), // Deep Aqua
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Animated Illustration
                  ScaleTransition(
                    scale: _illustrationScale,
                    child: Container(
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
                              'assets/images/illustrationNOBG.png',
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Tagline - Made more visible
                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'Balance your tasks.\n Balance your mind.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color:
                            Color.fromARGB(255, 72, 136, 160), // Soft Sky Blue
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),

                  // Animated Buttons
                  FadeTransition(
                    opacity: _buttonsOpacity,
                    child: Column(
                      children: [
                        // Get Started (Primary) - 3D Raised Blue Gradient
                        Center(
                          child: SizedBox(
                            width: ResponsiveUtils.getButtonMaxWidth(context),
                            child: Container(
                              height: ResponsiveUtils.getButtonHeight(context),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 70, 148, 176),
                                    const Color.fromARGB(255, 70, 148, 176)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 0, 0, 0)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 0, 0, 0)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginSignupScreen(),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Center(
                                    child: Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getButtonFontSize(
                                                context),
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF66B2D6),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Login - 3D Raised Blue Gradient
                        Center(
                          child: SizedBox(
                            width: ResponsiveUtils.getButtonMaxWidth(context),
                            child: Container(
                              height: ResponsiveUtils.getButtonHeight(context),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 70, 148, 176),
                                    const Color.fromARGB(255, 70, 148, 176)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 0, 0, 0)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 0, 0, 0)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: const Color(0xFF66B2D6),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginSignupScreen(
                                          initialTabIndex: 0,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Center(
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize:
                                            ResponsiveUtils.getButtonFontSize(
                                                context),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
