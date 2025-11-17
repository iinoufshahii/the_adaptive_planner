/// Authentication screen with tab-based login and signup forms.
/// Handles Firebase Auth operations with email/password, form validation, error handling.
/// Displays visual feedback with snackbars for success/error states.
import 'dart:ui';

import 'package:adaptive_planner/Screens/dashboard_screen.dart';
import 'package:adaptive_planner/Screens/forgot_password_screen.dart';
import 'package:adaptive_planner/dialogs/app_dialogs.dart';
import 'package:adaptive_planner/Theme/App_Theme.dart'; // Import light theme for the card
import 'package:adaptive_planner/Widgets/Responsive_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginSignupScreen extends StatefulWidget {
  final int initialTabIndex;
  const LoginSignupScreen({super.key, this.initialTabIndex = 1});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form Keys for validation
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Text Field Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Password visibility states
  bool _isLoginPasswordVisible = false;
  bool _isSignupPasswordVisible = false;
  bool _isSignupConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Incorrect email or password. Please check your credentials and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please use a stronger password.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // --- Authentication Logic ---
  Future<void> _login() async {
    final formState = _loginFormKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Login successful!',
          type: AppMessageType.success,
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorMessage = _friendlyAuthMessage(e);
        await showFloatingBottomDialog(
          context,
          message: errorMessage,
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Unexpected error: $e',
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    final formState = _signupFormKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text.trim(),
      );
      await userCredential.user
          ?.updateDisplayName(_signupNameController.text.trim());
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Account created successfully!',
          type: AppMessageType.success,
        );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (_) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final errorMessage = _friendlyAuthMessage(e);
        await showFloatingBottomDialog(
          context,
          message: errorMessage,
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        await showFloatingBottomDialog(
          context,
          message: 'Unexpected error: $e',
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a stack to layer the gradient and the content
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.5,
                colors: [
                  Color.fromARGB(255, 179, 232, 252), // Pale Aqua
                  Color.fromARGB(255, 150, 212, 226), // Soft Sky Blue
                  Color(0xFF66B2D6), // Dreamy Blue
                  Color.fromARGB(255, 70, 148, 176), // Deep Aqua
                ],
                stops: [0.0, 0.33, 0.66, 1.0],
              ),
            ),
          ),
          // Scrollable Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveUtils.getOuterPadding(context)),
              child: SizedBox(
                width: ResponsiveUtils.getCardMaxWidth(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Card - positioned lower to allow overlap
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 80), // Adjust this to control overlap amount
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.9),
                                  Colors.white.withValues(alpha: 0.7),
                                  Colors.white.withValues(alpha: 0.85),
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                                width: 2.5,
                              ),
                              boxShadow: [
                                // Far shadow (3D depth)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                                // Mid shadow (elevation)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                                // Close shadow (definition)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                // Highlight shadow (glass effect)
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Add top padding to account for overlapping image
                                const SizedBox(
                                    height:
                                        60), // Increased to prevent image cropping
                                // Tab Bar with modern styling - lowered position
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal:
                                        ResponsiveUtils.getTabMargin(context),
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    dividerHeight: 0,
                                    indicator: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        colors: [
                                          softBlue,
                                          const Color.fromARGB(
                                              255, 196, 216, 224)
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              softBlue.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.grey.shade600,
                                    labelStyle: TextStyle(
                                      fontSize: ResponsiveUtils.getTabFontSize(
                                          context),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                    tabs: const [
                                      Tab(text: 'Login'),
                                      Tab(text: 'Signup'),
                                    ],
                                  ),
                                ),
                                // Tab Content
                                SizedBox(
                                  height:
                                      ResponsiveUtils.getFormHeight(context),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildLoginForm(
                                          ResponsiveUtils
                                              .getFormHorizontalPadding(
                                                  context),
                                          ResponsiveUtils
                                              .getFormVerticalPadding(context),
                                          ResponsiveUtils.getButtonHeight(
                                              context),
                                          ResponsiveUtils.getButtonFontSize(
                                              context),
                                          ResponsiveUtils
                                              .getButtonVerticalPadding(
                                                  context)),
                                      _buildSignupForm(
                                          ResponsiveUtils
                                              .getFormHorizontalPadding(
                                                  context),
                                          ResponsiveUtils
                                              .getFormVerticalPadding(context),
                                          ResponsiveUtils.getButtonHeight(
                                              context),
                                          ResponsiveUtils.getButtonFontSize(
                                              context),
                                          ResponsiveUtils
                                              .getButtonVerticalPadding(
                                                  context)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image - positioned on top to overlap the card
                    Positioned(
                      top: -109, // Moved image higher to sit on top of card
                      child: Container(
                        height: 250, // Adjust image height
                        width: 350, // Adjust image width
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/Here.png',
                            fit: BoxFit.cover,
                          ),
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
    );
  }

  // --- Form Widgets ---
  Widget _buildLoginForm(
      double horizontalPadding,
      double verticalPadding,
      double buttonHeight,
      double buttonFontSize,
      double buttonVerticalPadding) {
    return Form(
      key: _loginFormKey,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(
                controller: _loginEmailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email.';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _loginPasswordController,
                label: 'Password',
                icon: Icons.lock_outline,
                showVisibilityToggle: true,
                isPasswordVisible: _isLoginPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isLoginPasswordVisible = !_isLoginPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [softBlue, const Color(0xFF66B2D6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: softBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _isLoading ? null : _login,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: buttonFontSize,
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: softBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm(
      double horizontalPadding,
      double verticalPadding,
      double buttonHeight,
      double buttonFontSize,
      double buttonVerticalPadding) {
    return Form(
      key: _signupFormKey,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: verticalPadding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(
                controller: _signupNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _signupEmailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email.';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _signupPasswordController,
                label: 'Password',
                icon: Icons.lock_outline,
                showVisibilityToggle: true,
                isPasswordVisible: _isSignupPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isSignupPasswordVisible = !_isSignupPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              _buildTextField(
                controller: _signupConfirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_outline,
                showVisibilityToggle: true,
                isPasswordVisible: _isSignupConfirmPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    _isSignupConfirmPasswordVisible =
                        !_isSignupConfirmPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value != _signupPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [softBlue, const Color(0xFF66B2D6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: softBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _isLoading ? null : _signup,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: buttonFontSize,
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
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable TextField Helper ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool showVisibilityToggle = false,
    bool? isPasswordVisible,
    VoidCallback? onVisibilityToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText:
            showVisibilityToggle ? !(isPasswordVisible ?? false) : obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: softBlue),
          suffixIcon: showVisibilityToggle
              ? IconButton(
                  icon: Icon(
                    (isPasswordVisible ?? false)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: softBlue,
                    size: 20,
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: softBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          errorStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFD32F2F),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            backgroundColor: Colors.white.withValues(alpha: 0.9),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: TextStyle(
          color: mutedNeutralDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
