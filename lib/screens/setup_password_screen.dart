import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/security_service.dart';

class SetupPasswordScreen extends StatefulWidget {
  const SetupPasswordScreen({super.key});

  @override
  State<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends State<SetupPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  Map<String, dynamic>? _passwordStrength;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    if (_passwordController.text.isNotEmpty) {
      setState(() {
        _passwordStrength = SecurityService.validatePasswordStrength(
          _passwordController.text,
        );
      });
    }
  }

  Future<void> _setupPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await SecurityService.setupMasterPassword(
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to set password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    if (_passwordStrength == null) return const SizedBox.shrink();

    final double score = _passwordStrength!['score']?.toDouble() ?? 0.0;
    final String strength = _passwordStrength!['level'] ?? 'Weak';

    Color strengthColor;
    switch (strength) {
      case 'Weak':
        strengthColor = Colors.red;
        break;
      case 'Medium':
        strengthColor = Colors.orange;
        break;
      case 'Strong':
        strengthColor = Colors.yellow;
        break;
      case 'Very Strong':
        strengthColor = Colors.green;
        break;
      default:
        strengthColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Password Strength: ',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            Text(
              strength,
              style: GoogleFonts.inter(
                color: strengthColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 5.0,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Header
                    Text(
                      'Create Master Password',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This password will protect all your saved passwords. You can use any length you prefer.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Password Field
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
                      keyboardType: TextInputType.text,
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
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),

                    // Password Strength Indicator
                    _buildPasswordStrengthIndicator(),

                    const SizedBox(height: 24),

                    // Confirm Password Field
                    Text(
                      'Confirm Password',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      keyboardType: TextInputType.text,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Confirm your master password',
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
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    const Spacer(),

                    // Create Password Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setupPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Create Master Password',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),
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
