import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to manage the app's internal encryption key.
///
/// The key is generated once (256-bit random) and stored securely.
/// We DO NOT derive this key from a user password to allow password-less
/// automated backups. If the user later changes their master password,
/// it does not affect backup encryption because the key is independent.
class EncryptionKeyService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'app_encryption_key_v1';

  /// Get existing key or create a new one.
  Future<List<int>> getOrCreateKey() async {
    String? base64Key = await _storage.read(key: _keyName);
    if (base64Key == null) {
      final keyBytes = _generateRandomBytes(32); // 256-bit
      base64Key = base64Encode(keyBytes);
      await _storage.write(key: _keyName, value: base64Key);
      return keyBytes;
    }
    return base64Decode(base64Key);
  }

  /// Generate cryptographically secure random bytes.
  List<int> _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
