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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 50;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // ส่วนว่างด้านบน - ลดลงมากขึ้นเมื่อมี keyboard
                  SizedBox(
                    height: isKeyboardVisible
                        ? 20 // ลดเป็น 20 pixels เมื่อมี keyboard
                        : (screenHeight * 0.15),
                  ),

                  // Login Widget Card - อยู่ตรงกลางด้านบน
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        isKeyboardVisible ? 24.0 : 32.0,
                      ), // ลด padding เมื่อมี keyboard
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // App Icon - ลดขนาดเมื่อมี keyboard
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isKeyboardVisible ? 60 : 80,
                              height: isKeyboardVisible ? 60 : 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(
                                  isKeyboardVisible ? 15 : 20,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C5CE7,
                                    ).withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                size: isKeyboardVisible ? 30 : 40,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: isKeyboardVisible ? 16 : 24),

                            // App Name
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: GoogleFonts.inter(
                                fontSize: isKeyboardVisible ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              child: const Text('PasswordWallet'),
                            ),

                            SizedBox(height: isKeyboardVisible ? 4 : 8),

                            // ซ่อน subtitle เมื่อมี keyboard เพื่อประหยัดพื้นที่
                            if (!isKeyboardVisible) ...[
                              Text(
                                'Enter your master password',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ] else ...[
                              const SizedBox(height: 20),
                            ],

                            // Password Text Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter your master password',
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1E1E2E),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
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
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Login Button
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
                      ),
                    ),
                  ),

                  // Spacing ด้านล่าง - ใช้ SizedBox แทน Spacer เพื่อป้องกัน RenderFlex error
                  SizedBox(height: isKeyboardVisible ? 40 : 104),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
