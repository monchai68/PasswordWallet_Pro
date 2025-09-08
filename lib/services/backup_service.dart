import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../database/database_helper.dart';

/// Simple Backup and Restore service (no heavy encryption)
class BackupService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Simple hash
  String _simpleHash(String password) {
    int hash = 0;
    for (int i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash + password.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Create a simple backup file - fast, no heavy encryption
  Future<Map<String, dynamic>> createBackup({
    required String password,
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
        'password_hash': _simpleHash(password),
        'data': {
          'version': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'categories': categories,
          'fields': fields,
          'password_items': items,
        },
      };

      onProgress?.call('Saving...');

      // Encode JSON and ask user where to save
      final jsonBytes = utf8.encode(jsonEncode(backupData));
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

  /// Pick a backup file and restore
  Future<Map<String, dynamic>> pickAndRestoreBackup({
    required String password,
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
        password: password,
        mode: mode,
        onProgress: onProgress,
      );
    } catch (e) {
      return {'success': false, 'message': 'Error selecting file: $e'};
    }
  }

  /// Restore from simple backup file
  Future<Map<String, dynamic>> restoreBackup({
    required Uint8List fileBytes,
    required String password,
    String mode = 'merge',
    Function(String)? onProgress,
  }) async {
    try {
      onProgress?.call('Reading backup file...');

      // Parse JSON payload
      final backupData =
          jsonDecode(utf8.decode(fileBytes)) as Map<String, dynamic>;

      // Verify password
      final storedHash = backupData['password_hash'] as String?;
      if (storedHash == null || storedHash != _simpleHash(password)) {
        return {'success': false, 'message': 'Wrong password!'};
      }

      onProgress?.call('Extracting data...');

      final data = backupData['data'] as Map<String, dynamic>;
      final categories = (data['categories'] as List)
          .cast<Map<String, dynamic>>();
      final fields = (data['fields'] as List).cast<Map<String, dynamic>>();
      final items = (data['password_items'] as List)
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
