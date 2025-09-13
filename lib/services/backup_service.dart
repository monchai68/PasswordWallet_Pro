import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'encryption_key_service.dart';

import 'package:file_picker/file_picker.dart';

import '../database/database_helper.dart';

/// Backup and Restore service with internal key encryption (v2) and
/// backward compatibility for legacy (v1) password-based backups.
class BackupService {
  final DatabaseHelper _db = DatabaseHelper();
  final EncryptionKeyService _keyService = EncryptionKeyService();

  // ---- New v2 format constants ----
  // Format: PWMV2:base64(iv):base64(cipher):base64(hmac)
  static const String v2Prefix = 'PWMV2';

  // HMAC key derivation: split the 32-byte master key into two halves.
  Map<String, Uint8List> _deriveEncryptionAndMacKeys(List<int> masterKey) {
    final keyBytes = Uint8List.fromList(masterKey);
    final encKey = keyBytes.sublist(0, 16); // 128-bit AES key (sufficient)
    final macKey = keyBytes.sublist(16); // remaining 128-bit for HMAC
    return {'enc': encKey, 'mac': macKey};
  }

  String _encryptV2(String plainText, List<int> masterKey) {
    final keys = _deriveEncryptionAndMacKeys(masterKey);
    final encKey = encrypt.Key(Uint8List.fromList(keys['enc']!));
    final ivBytes = _secureRandomBytes(16);
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final aes = encrypt.Encrypter(
      encrypt.AES(encKey, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    final cipher = aes.encrypt(plainText, iv: iv);

    // HMAC over prefix|iv|cipher
    final macInput = <int>[]
      ..addAll(utf8.encode(v2Prefix))
      ..addAll(ivBytes)
      ..addAll(cipher.bytes);
    final hmacSha256 = Hmac(sha256, keys['mac']!);
    final mac = hmacSha256.convert(macInput).bytes;

    return [
      v2Prefix,
      base64Encode(ivBytes),
      base64Encode(cipher.bytes),
      base64Encode(mac),
    ].join(':');
  }

  String _decryptV2(String data, List<int> masterKey) {
    final parts = data.split(':');
    if (parts.length != 4 || parts[0] != v2Prefix) {
      throw Exception('Invalid v2 format');
    }
    final ivBytes = base64Decode(parts[1]);
    final cipherBytes = base64Decode(parts[2]);
    final macBytes = base64Decode(parts[3]);

    final keys = _deriveEncryptionAndMacKeys(masterKey);

    // Verify HMAC
    final macInput = <int>[]
      ..addAll(utf8.encode(v2Prefix))
      ..addAll(ivBytes)
      ..addAll(cipherBytes);
    final hmacSha256 = Hmac(sha256, keys['mac']!);
    final expectedMac = hmacSha256.convert(macInput).bytes;
    if (!_constantTimeEquals(macBytes, expectedMac)) {
      throw Exception('Integrity check failed');
    }

    final encKey = encrypt.Key(Uint8List.fromList(keys['enc']!));
    final iv = encrypt.IV(ivBytes);
    final aes = encrypt.Encrypter(
      encrypt.AES(encKey, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    final decrypted = aes.decrypt(encrypt.Encrypted(cipherBytes), iv: iv);
    return decrypted;
  }

  // Legacy v1 decrypt (format ivBase64:encryptedBase64 using SHA256(password) first 32 chars)
  String _decryptLegacyV1(String encryptedText, String password) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted format');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final data = parts[1];
    final keyString = sha256
        .convert(utf8.encode(password))
        .toString()
        .substring(0, 32);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key.fromUtf8(keyString)),
    );
    return encrypter.decrypt64(data, iv: iv);
  }

  List<int> _secureRandomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Create an encrypted backup file using internal key (v2).
  Future<Map<String, dynamic>> createBackup({
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Reading database...');

      final db = await _db.database;
      final categories = await db.query('categories');
      final fields = await db.query('fields');
      final items = await db.query('password_items');

      onProgress?.call('Preparing backup...');

      // Build lightweight JSON payload
      final backupData = {
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'categories': categories,
        'fields': fields,
        'password_items': items,
      };

      onProgress?.call('Encrypting (v2)...');

      final jsonString = jsonEncode(backupData);
      final masterKey = await _keyService.getOrCreateKey();
      final encryptedString = _encryptV2(jsonString, masterKey);
      final jsonBytes = utf8.encode(encryptedString);
      final String defaultName =
          'PasswordWallet_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pwmbackup';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform
            .saveFile(
              dialogTitle: 'Save Backup',
              fileName: defaultName,
              type: FileType.custom,
              allowedExtensions: ['pwmbackup'],
              bytes: Uint8List.fromList(jsonBytes),
            )
            .timeout(const Duration(seconds: 30));
      } catch (_) {
        // Ignore picker errors/timeouts; treat as cancelled
      }

      onProgress?.call('Completed');

      return {
        'success': true,
        'message': savedPath != null
            ? 'Backup saved'
            : 'Backup ready (save cancelled)',
        'filePath': savedPath,
        'counts': {
          'categories': categories.length,
          'fields': fields.length,
          'items': items.length,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Build an encrypted backup entirely in memory (no file picker) and
  /// return the encrypted bytes plus counts for UI/analytics.
  Future<Map<String, dynamic>> createEncryptedBackupInMemory({
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Reading database...');
      final db = await _db.database;
      final categories = await db.query('categories');
      final fields = await db.query('fields');
      final items = await db.query('password_items');

      onProgress?.call('Preparing backup...');
      final backupData = {
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'categories': categories,
        'fields': fields,
        'password_items': items,
      };

      onProgress?.call('Encrypting (v2)...');
      final masterKey = await _keyService.getOrCreateKey();
      final encryptedString = _encryptV2(jsonEncode(backupData), masterKey);
      final bytes = Uint8List.fromList(utf8.encode(encryptedString));

      onProgress?.call('Completed');
      return {
        'success': true,
        'encryptedBytes': bytes,
        'counts': {
          'categories': categories.length,
          'fields': fields.length,
          'items': items.length,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Pick a backup file and restore (auto-detects v2 or legacy).
  Future<Map<String, dynamic>> pickAndRestoreBackup({
    String legacyPassword = '', // only needed for legacy files
    String mode = 'merge',
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Opening file picker...');

      final picked = await FilePicker.platform.pickFiles(
        type: FileType.any, // Changed from custom to any to accept all files
        // allowedExtensions: ['pwmbackup'], // Removed this line
        withData: true,
        dialogTitle: 'Select backup file',
      );

      if (picked == null || picked.files.isEmpty) {
        return {'success': false, 'message': 'No file selected'};
      }

      final file = picked.files.single;
      if (file.bytes == null) {
        return {'success': false, 'message': 'Could not read file data'};
      }

      onProgress?.call('File selected: ${file.name}');

      return await restoreBackup(
        fileBytes: file.bytes!,
        legacyPassword: legacyPassword,
        mode: mode,
        onProgress: onProgress,
      );
    } catch (e) {
      return {'success': false, 'message': 'Error selecting file: $e'};
    }
  }

  /// Restore from backup file (v2 preferred, legacy supported).
  Future<Map<String, dynamic>> restoreBackup({
    required Uint8List fileBytes,
    String legacyPassword = '',
    String mode = 'merge',
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Reading backup file...');

      // Decrypt and parse JSON payload
      final fileContent = utf8.decode(fileBytes);
      String jsonString;
      Map<String, dynamic> backupData;
      if (fileContent.startsWith(v2Prefix)) {
        // v2 format
        try {
          final masterKey = await _keyService.getOrCreateKey();
          jsonString = _decryptV2(fileContent, masterKey);
          backupData = jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          return {
            'success': false,
            'message': 'Integrity/Decryption failed: $e',
          };
        }
      } else if (fileContent.contains(':') && legacyPassword.isNotEmpty) {
        // presume legacy encrypted format iv:cipher
        try {
          jsonString = _decryptLegacyV1(fileContent, legacyPassword);
          backupData = jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          return {'success': false, 'message': 'Legacy decryption failed'};
        }
      } else if (fileContent.trim().startsWith('{')) {
        // plain JSON fallback
        backupData = jsonDecode(fileContent) as Map<String, dynamic>;
      } else {
        return {'success': false, 'message': 'Unknown backup format'};
      }

      onProgress?.call('Extracting data...');

      final categories = (backupData['categories'] as List)
          .cast<Map<String, dynamic>>();
      final fields = (backupData['fields'] as List)
          .cast<Map<String, dynamic>>();
      final items = (backupData['password_items'] as List)
          .cast<Map<String, dynamic>>();

      onProgress?.call('Updating database...');

      // Apply to DB (merge or replace)
      final db = await _db.database;

      if (mode == 'replace') {
        await db.delete('password_items');
        await db.delete('fields');
        await db.delete('categories');
      }

      // Build category name -> id mapping
      final Map<String, int> categoryIdByName = {};
      final existingCats = await db.query('categories');
      for (final c in existingCats) {
        categoryIdByName[c['name'] as String] = c['id'] as int;
      }

      // Upsert categories
      for (final c in categories) {
        final name = c['name'] as String;
        final icon = (c['icon_code_point'] ?? 0xe2bc) as int;
        final color = (c['color_value'] ?? 4294945792) as int;
        final createdAt =
            c['created_at'] as String? ?? DateTime.now().toIso8601String();
        if (categoryIdByName.containsKey(name)) {
          await db.update(
            'categories',
            {'name': name, 'icon_code_point': icon, 'color_value': color},
            where: 'id = ?',
            whereArgs: [categoryIdByName[name]],
          );
        } else {
          final id = await db.insert('categories', {
            'name': name,
            'icon_code_point': icon,
            'color_value': color,
            'created_at': createdAt,
          });
          categoryIdByName[name] = id;
        }
      }

      // Map backup category id -> name
      final Map<int, String> backupCatIdToName = {};
      for (final c in categories) {
        backupCatIdToName[c['id'] as int] = c['name'] as String;
      }

      // Upsert fields
      for (final f in fields) {
        final backupCatId = f['category_id'] as int;
        final catName = backupCatIdToName[backupCatId];
        if (catName == null) continue;
        final newCatId = categoryIdByName[catName];
        if (newCatId == null) continue;

        final name = f['name'] as String;
        final isVisible = (f['is_visible'] ?? 1) as int;
        final isRequired = (f['is_required'] ?? 0) as int;
        final isMasked = (f['is_masked'] ?? 0) as int;
        final order = (f['order_index'] ?? 0) as int;

        final existing = await db.query(
          'fields',
          where: 'category_id = ? AND name = ?',
          whereArgs: [newCatId, name],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          await db.update(
            'fields',
            {
              'is_visible': isVisible,
              'is_required': isRequired,
              'is_masked': isMasked,
              'order_index': order,
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          await db.insert('fields', {
            'category_id': newCatId,
            'name': name,
            'is_visible': isVisible,
            'is_required': isRequired,
            'is_masked': isMasked,
            'order_index': order,
          });
        }
      }

      // Upsert items by (category_id, title)
      for (final it in items) {
        final backupCatId = it['category_id'] as int;
        final catName = backupCatIdToName[backupCatId];
        if (catName == null) continue;
        final newCatId = categoryIdByName[catName];
        if (newCatId == null) continue;

        final title = (it['title'] ?? '') as String;
        if (title.isEmpty) continue;
        final createdAt =
            it['created_at'] as String? ?? DateTime.now().toIso8601String();
        final updatedAt = it['updated_at'] as String? ?? createdAt;
        final isFavorite = (it['is_favorite'] ?? 0) as int;
        final fieldValues = (it['field_values'] ?? '') as String;

        final existing = await db.query(
          'password_items',
          where: 'category_id = ? AND title = ?',
          whereArgs: [newCatId, title],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          await db.update(
            'password_items',
            {
              'field_values': fieldValues,
              'updated_at': updatedAt,
              'is_favorite': isFavorite,
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        } else {
          await db.insert('password_items', {
            'category_id': newCatId,
            'title': title,
            'field_values': fieldValues,
            'created_at': createdAt,
            'updated_at': updatedAt,
            'is_favorite': isFavorite,
          });
        }
      }

      onProgress?.call('Completed');

      return {
        'success': true,
        'message': 'Restore completed',
        'counts': {
          'categories': categories.length,
          'fields': fields.length,
          'items': items.length,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
