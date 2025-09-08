import 'package:flutter/material.dart';
import 'services/security_service.dart';
import 'screens/setup_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/fingerprint_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PasswordWalletApp());
}

class PasswordWalletApp extends StatelessWidget {
  const PasswordWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PasswordWallet',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/setup': (context) => const SetupPasswordScreen(),
        '/login': (context) => const LoginScreen(),
        '/fingerprint': (context) => const FingerprintScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();
  }

  Future<void> _checkPasswordStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final hasPassword = await SecurityService.hasPassword();

      if (hasPassword) {
        // Check if fingerprint is enabled
        final prefs = await SharedPreferences.getInstance();
        final isFingerprintEnabled =
            prefs.getBool('fingerprint_enabled') ?? false;

        if (isFingerprintEnabled) {
          Navigator.pushReplacementNamed(context, '/fingerprint');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3142),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D3142),
              const Color(0xFF6C5CE7).withOpacity(0.8),
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(Icons.account_balance_wallet, size: 100, color: Colors.white),

            SizedBox(height: 20),

            // App Name
            Text(
              'PasswordWallet',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),

            // Tagline
            Text(
              'Secure • Simple • Safe',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),

            SizedBox(height: 50),

            // Loading Indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
          ],
        ),
      ),
    );
  }
}
