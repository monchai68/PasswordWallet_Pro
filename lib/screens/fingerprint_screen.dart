import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

class FingerprintScreen extends StatefulWidget {
  const FingerprintScreen({super.key});

  @override
  State<FingerprintScreen> createState() => _FingerprintScreenState();
}

class _FingerprintScreenState extends State<FingerprintScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      if (isAvailable && canCheckBiometrics) {
        final List<BiometricType> availableBiometrics = await _localAuth
            .getAvailableBiometrics();

        if (availableBiometrics.isNotEmpty) {
          // Automatically show biometric prompt immediately
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _authenticateWithBiometrics();
            }
          });
        } else {
          // No biometrics available, go to password login
          _goToPasswordLogin();
        }
      } else {
        // Device doesn't support biometrics, go to password login
        _goToPasswordLogin();
      }
    } catch (e) {
      print('Error checking biometric support: $e');
      // If error, fallback to password login
      _goToPasswordLogin();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please scan your fingerprint to unlock the app',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      setState(() {
        _isAuthenticating = false;
      });

      if (didAuthenticate) {
        // Authentication successful - go to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Authentication was cancelled or failed
        // Go directly to password login
        print('Biometric authentication was cancelled or failed');
        _goToPasswordLogin();
      }
    } catch (e) {
      print('Biometric authentication error: $e');
      setState(() {
        _isAuthenticating = false;
      });

      // Show error and allow retry
      _showErrorDialog(
        'Biometric authentication failed. You can try again or use password login.',
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Authentication Error',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Try Again',
              style: GoogleFonts.inter(
                color: const Color(0xFF5A67D8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _goToPasswordLogin();
            },
            child: Text(
              'Use Password',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPasswordLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A67D8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),

            // Text
            Text(
              'Preparing biometric authentication...',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
