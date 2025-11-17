/// Password reset screen with Firebase email-based recovery.
/// Validates email, sends reset link via Firebase Auth, displays success/error feedback.
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dialogs/app_dialogs.dart';
import '../Theme/App_Theme.dart';
import '../Widgets/Responsive_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showFeedback(String message, {bool isError = false}) async {
    if (!mounted) return;
    await showFloatingBottomDialog(
      context,
      message: message,
      type: isError ? AppMessageType.error : AppMessageType.success,
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _emailSent = true);
        await _showFeedback(
          'Password reset link sent! Check your email.',
          isError: false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      bool isActualError = true;
      switch (e.code) {
        case 'user-not-found':
          // For security, we give a generic message
          errorMessage =
              'If an account exists for this email, a password reset link has been sent.';
          isActualError = false;
          if (mounted) setState(() => _emailSent = true);
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message ?? "Unknown error"}';
      }
      await _showFeedback(errorMessage, isError: isActualError);
    } catch (e) {
      await _showFeedback(
        'Unexpected error: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _emailSent = false);
    await _sendPasswordResetEmail();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
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
            stops: [0.0, 0.10, 0.9, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
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
                      padding: const EdgeInsets.only(top: 80),
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
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                  ResponsiveUtils.getFormHorizontalPadding(
                                      context)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.arrow_back),
                                        color: mutedNeutralDark,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Reset Password',
                                          style: TextStyle(
                                            fontSize:
                                                ResponsiveUtils.getTabFontSize(
                                                    context),
                                            fontWeight: FontWeight.bold,
                                            color: mutedNeutralDark,
                                            letterSpacing: 0.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Icon(
                                    _emailSent
                                        ? Icons.mark_email_read
                                        : Icons.lock_reset,
                                    size: ResponsiveUtils.isMobile(context)
                                        ? 64
                                        : 80,
                                    color: softBlue,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _emailSent
                                        ? 'Check Your Email'
                                        : 'Forgot Password?',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: mutedNeutralDark,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _emailSent
                                        ? 'We\'ve sent a password reset link to your email address. Please check your inbox and spam folder.'
                                        : 'Enter your email address and we\'ll send you a link to reset your password.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: mutedNeutralDark.withValues(
                                          alpha: 0.7),
                                      height: 1.4,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  if (!_emailSent) ...[
                                    Form(
                                      key: _formKey,
                                      child: TextFormField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          labelText: 'Email Address',
                                          prefixIcon: const Icon(
                                              Icons.email_outlined,
                                              color: softBlue),
                                          filled: true,
                                          fillColor: Colors.white
                                              .withValues(alpha: 0.9),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            borderSide: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
                                                width: 1.5),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            borderSide: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
                                                width: 1.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            borderSide: const BorderSide(
                                                color: softBlue, width: 2),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 14),
                                          labelStyle: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.9),
                                          ),
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                        ),
                                        style: TextStyle(
                                          color: mutedNeutralDark,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your email address';
                                          }
                                          if (!RegExp(
                                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                              .hasMatch(value.trim())) {
                                            return 'Please enter a valid email address';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: SizedBox(
                                        width:
                                            ResponsiveUtils.getButtonMaxWidth(
                                                context),
                                        child: Container(
                                          height:
                                              ResponsiveUtils.getButtonHeight(
                                                  context),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                softBlue,
                                                const Color(0xFF66B2D6)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 8),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: softBlue.withValues(
                                                    alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: InkWell(
                                              onTap: _isLoading
                                                  ? null
                                                  : _sendPasswordResetEmail,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Center(
                                                child: Text(
                                                  'Send Reset Link',
                                                  style: TextStyle(
                                                      fontSize: ResponsiveUtils
                                                          .getButtonFontSize(
                                                              context),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                                255, 162, 244, 182)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF1E88E5)
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline,
                                              color: const Color.fromARGB(
                                                  255, 17, 213, 46),
                                              size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Email sent to:\n${_emailController.text.trim()}',
                                              style: TextStyle(
                                                  color: const Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.blue.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.tips_and_updates,
                                                  color: Colors.blue.shade600,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Text('Tips:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                      color: Colors
                                                          .blue.shade700)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '• Check your spam/junk folder\n• The link expires in 1 hour\n• You can request a new link anytime',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: const Color(0xFF1E88E5),
                                                height: 1.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: SizedBox(
                                        width:
                                            ResponsiveUtils.getButtonMaxWidth(
                                                context),
                                        child: Container(
                                          height:
                                              ResponsiveUtils.getButtonHeight(
                                                  context),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                softBlue,
                                                const Color(0xFF66B2D6)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 8),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: softBlue.withValues(
                                                    alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: InkWell(
                                              onTap: _resendEmail,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Center(
                                                child: Text(
                                                  'Resend Email',
                                                  style: TextStyle(
                                                      fontSize: ResponsiveUtils
                                                          .getButtonFontSize(
                                                              context),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image - positioned on top to overlap the card
                    Positioned(
                      top: -109,
                      child: Container(
                        height: 250,
                        width: 350,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/Forgot.png',
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
        ),
      ),
    );
  }
}
