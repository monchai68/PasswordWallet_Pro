import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/security_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await SecurityService.verifyMasterPassword(
        _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _errorMessage = 'Incorrect password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        title: Text(
          'Forgot Password?',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you forgot your master password, you\'ll need to reset the app and lose all saved data.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SecurityService.clearAllData();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/setup');
              }
            },
            child: Text(
              'Reset App',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible =
        keyboardHeight >
        100; // เปลี่ยนจาก > 0 เป็น > 100 เพื่อป้องกัน false positive

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24.0,
            24.0,
            24.0,
            isKeyboardVisible ? keyboardHeight + 24 : 24.0,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  (isKeyboardVisible ? keyboardHeight + 48 : 48),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Section
                    Column(
                      children: [
                        // ปรับ spacing ตาม keyboard
                        SizedBox(height: isKeyboardVisible ? 10 : 40),

                        // App Logo
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isKeyboardVisible ? 60 : 120,
                          height: isKeyboardVisible ? 60 : 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7),
                            borderRadius: BorderRadius.circular(
                              isKeyboardVisible ? 15 : 25,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: isKeyboardVisible ? 30 : 60,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: isKeyboardVisible ? 8 : 24),

                        // App Name
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: GoogleFonts.inter(
                            fontSize: isKeyboardVisible ? 20 : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          child: const Text('PasswordWallet'),
                        ),

                        if (!isKeyboardVisible) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Enter your master password to continue',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],

                        SizedBox(height: isKeyboardVisible ? 16 : 32),
                      ],
                    ),

                    // Form Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master Password',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your master password',
                            hintStyle: GoogleFonts.inter(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6C5CE7),
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _login(),
                        ),

                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],

                        // Forgot Password Link (ซ่อนเมื่อมี keyboard)
                        if (!isKeyboardVisible) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF6C5CE7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Bottom Section - Login Button
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              disabledBackgroundColor: const Color(
                                0xFF6C5CE7,
                              ).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Unlock',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
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
