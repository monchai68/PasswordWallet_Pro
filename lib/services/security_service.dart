import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _masterPasswordKey = 'master_password_hash';
  static const String _saltKey = 'password_salt';
  static const String _isSetupKey = 'is_setup_complete';

  /// Check if this is the first time launching the app
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_isSetupKey);
  }

  /// Check if master password has been set up
  static Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_masterPasswordKey) &&
        prefs.containsKey(_saltKey) &&
        prefs.getBool(_isSetupKey) == true;
  }

  /// Generate a random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Hash password with salt using SHA-256
  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Setup master password (first time setup)
  static Future<bool> setupMasterPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Generate salt and hash password
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      // Save to preferences
      await prefs.setString(_saltKey, salt);
      await prefs.setString(_masterPasswordKey, hashedPassword);
      await prefs.setBool(_isSetupKey, true);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify master password
  static Future<bool> verifyMasterPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final salt = prefs.getString(_saltKey);
      final storedHash = prefs.getString(_masterPasswordKey);

      if (salt == null || storedHash == null) {
        return false;
      }

      final hashedPassword = _hashPassword(password, salt);
      return hashedPassword == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Generate secure random password
  static String generateRandomPassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const String lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String characters = '';
    if (includeLowercase) characters += lowercaseLetters;
    if (includeUppercase) characters += uppercaseLetters;
    if (includeNumbers) characters += numbers;
    if (includeSymbols) characters += symbols;

    if (characters.isEmpty) characters = lowercaseLetters;

    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  /// Validate password strength (ยืดหยุ่นสำหรับผู้ใช้)
  static Map<String, dynamic> validatePasswordStrength(String password) {
    double score = 0;
    List<String> feedback = [];

    // ตรวจสอบความยาว (ไม่บังคับ 8 ตัว)
    if (password.length >= 6) {
      score += 1;
      if (password.length >= 8) {
        score += 1; // bonus สำหรับ 8+ ตัว
      }
    } else if (password.length >= 4) {
      score += 0.5; // ให้คะแนนบางส่วนสำหรับ 4-5 ตัว
    }

    // ตรวจสอบประเภทตัวอักษร (ไม่บังคับให้มีครบทุกแบบ)
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    }

    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    }

    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    }

    // คำนวณความแข็งแรง
    String strength;
    if (password.isEmpty) {
      strength = 'Empty';
      feedback.add('กรุณาใส่รหัสผ่าน');
    } else if (score <= 1) {
      strength = 'Very Weak';
      feedback.add('รหัสผ่านง่ายเกินไป');
    } else if (score <= 2) {
      strength = 'Weak';
      feedback.add('ควรเพิ่มความปลอดภัย');
    } else if (score <= 3) {
      strength = 'Medium';
      feedback.add('รหัสผ่านพอใช้ได้');
    } else if (score <= 4) {
      strength = 'Strong';
      feedback.add('รหัสผ่านแข็งแรง');
    } else {
      strength = 'Very Strong';
      feedback.add('รหัสผ่านแข็งแรงมาก');
    }

    return {'score': score, 'strength': strength, 'feedback': feedback};
  }

  /// Clear all stored data (for app reset)
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      return false;
    }
  }
}
