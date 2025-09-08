import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/security_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _updatePassword(String newPassword) async {
    try {
      return await SecurityService.setupMasterPassword(newPassword);
    } catch (e) {
      return false;
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if new password and confirm password match
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showErrorDialog('New password and confirm password do not match.');
        return;
      }

      // Update password directly (no need to verify current password since user is already authenticated)
      final success = await _updatePassword(_newPasswordController.text);

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Failed to update password. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A67D8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Success',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
        ),
        content: Text(
          'Your password has been changed successfully.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to settings
            },
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A67D8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A67D8), width: 2),
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red[400]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_outline,
                color: Colors.grey[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Change Password',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New password',
                  obscureText: _obscureNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    return null;
                  },
                ),

                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm new password',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 48),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A67D8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'OK',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                // Add some bottom padding to ensure content doesn't get cut off
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
