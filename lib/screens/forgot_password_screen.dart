// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

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

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : mintGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _emailSent = true);
        _showFeedback(
          'Password reset email sent! Check your inbox and spam folder.',
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          // For security, we give a generic message
          errorMessage =
              'If an account exists for this email, a password reset link has been sent.';
          setState(() => _emailSent = true);
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      _showFeedback(errorMessage, isError: e.code != 'user-not-found');
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [softBlue, Color(0xFF0E97DB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                                color: mutedNeutralDark,
                              ),
                              const Expanded(
                                child: Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 18,
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
                            _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                            size: 64,
                            color: softBlue,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _emailSent ? 'Check Your Email' : 'Forgot Password?',
                            style: theme.textTheme.headlineSmall?.copyWith(
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
                              color: mutedNeutralDark.withOpacity(0.7),
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
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined, color: softBlue),
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: softBlue, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [softBlue, Colors.blue.shade500]),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(color: softBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                                        BoxShadow(color: softBlue.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading ? null : _sendPasswordResetEmail,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: const Text(
                                            'Send Reset Link',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                                          ),
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
                                color: mintGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: mintGreen.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: mintGreen, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Email sent to:\n${_emailController.text.trim()}',
                                      style: TextStyle(color: mintGreen, fontWeight: FontWeight.w500, fontSize: 14),
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
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.tips_and_updates, color: Colors.blue.shade600, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Tips:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.blue.shade700)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Check your spam/junk folder\n• The link expires in 1 hour\n• You can request a new link anytime',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [mintGreen, Colors.green.shade500]),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(color: mintGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                                        BoxShadow(color: mintGreen.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _resendEmail,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          child: const Text(
                                            'Resend Email',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                                          ),
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
          ),
        ),
      ),
    );
  }
}
