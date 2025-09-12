import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';
import '../services/csv_service.dart';
import '../services/backup_service.dart';
import '../services/google_drive_service.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _fingerprintEnabled = false;
  final CSVService _csvService = CSVService();
  bool _isImporting = false;
  final BackupService _backupService = BackupService();
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadFingerprintSetting();
  }

  Future<void> _loadFingerprintSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fingerprintEnabled = prefs.getBool('fingerprint_enabled') ?? false;
    });
  }

  Future<void> _saveFingerprintSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fingerprint_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF5A67D8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Change password',
            subtitle: 'Change your master password for security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _buildFingerprintItem(),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.backup_outlined,
            title: 'Backup',
            subtitle: 'Backup your data to cloud or local storage',
            onTap: () {
              _showBackupDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.restore_outlined,
            title: 'Restore',
            subtitle: 'Restore data from backup file',
            onTap: () {
              _showRestoreDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.file_upload_outlined,
            title: 'Import CSV',
            subtitle: 'Import password data from CSV file',
            onTap: () {
              _showImportCSVDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.file_download_outlined,
            title: 'Export CSV',
            subtitle: 'Export password data to CSV file',
            onTap: () {
              _showExportCSVDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.cloud_sync_outlined,
            title: 'Sync to cloud',
            subtitle: 'Sync your data to the cloud',
            onTap: () {
              _performAutomaticCloudBackup();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey[600], size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey[300]);
  }

  Widget _buildFingerprintItem() {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.fingerprint, color: Colors.grey[600], size: 24),
        ),
        title: Text(
          'Fingerprint',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Use fingerprint to unlock the app',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: _fingerprintEnabled,
          onChanged: (bool value) async {
            setState(() {
              _fingerprintEnabled = value;
            });
            await _saveFingerprintSetting(value);
            _showFingerprintMessage(value);
          },
          activeThumbColor: const Color(0xFF5A67D8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
      ),
    );
  }

  void _showFingerprintMessage(bool enabled) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          enabled ? 'Fingerprint Enabled' : 'Fingerprint Disabled',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          enabled
              ? 'Fingerprint authentication has been enabled for this app.'
              : 'Fingerprint authentication has been disabled for this app.',
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

  void _showBackupDialog() {
    final passwordController = TextEditingController();
    bool obscure = true;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Backup Data',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create an encrypted backup file (.pwmbackup).',
                style: GoogleFonts.inter(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Encryption password',
                  suffixIcon: StatefulBuilder(
                    builder: (context, setSB) {
                      return IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setSB(() => obscure = !obscure),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final pwd = passwordController.text;
                if (pwd.isEmpty) return;

                // Close current dialog first
                Navigator.pop(context);

                // Wait a frame for the dialog to close completely
                await Future.delayed(const Duration(milliseconds: 100));

                // Call separate function to perform backup
                if (mounted) {
                  _performBackup(pwd);
                }
              },
              child: Text(
                'Backup',
                style: GoogleFonts.inter(color: const Color(0xFF5A67D8)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreDialog() {
    final passwordController = TextEditingController();
    bool obscure = true;
    String mode = 'merge';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Restore Data',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setSB) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restore from .pwmbackup file',
                    style: GoogleFonts.inter(),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: mode,
                    items: const [
                      DropdownMenuItem(value: 'merge', child: Text('Merge')),
                      DropdownMenuItem(
                        value: 'replace',
                        child: Text('Replace'),
                      ),
                    ],
                    onChanged: (v) => setSB(() => mode = v ?? 'merge'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Encryption password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setSB(() => obscure = !obscure),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final pwd = passwordController.text;
                if (pwd.isEmpty) return;

                // Close current dialog first
                Navigator.pop(context);

                // Wait a frame for the dialog to close completely
                await Future.delayed(const Duration(milliseconds: 100));

                // Call separate function to perform restore
                if (mounted) {
                  _performRestore(pwd, mode);
                }
              },
              child: Text(
                'Restore',
                style: GoogleFonts.inter(color: const Color(0xFF5A67D8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBackup(String password) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
            ),
            const SizedBox(height: 16),
            Text('Creating backup...', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );

    try {
      // Do the backup work
      final result = await _backupService.createBackup(
        password: password,
        onProgress: (message) {
          // Just do work, no UI updates
        },
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        _showBackupRestoreResult(result, title: 'Backup');
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) {
        Navigator.pop(context);
        _showBackupRestoreResult({
          'success': false,
          'message': 'An error occurred: $e',
        }, title: 'Backup');
      }
    }
  }

  Future<void> _performRestore(String password, String mode) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
            ),
            const SizedBox(height: 16),
            Text('Restoring data...', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );

    try {
      // Do the restore work
      final result = await _backupService.pickAndRestoreBackup(
        password: password,
        mode: mode,
        onProgress: (message) {
          // Just do work, no UI updates
        },
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        _showBackupRestoreResult(result, title: 'Restore');
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) {
        Navigator.pop(context);
        _showBackupRestoreResult({
          'success': false,
          'message': 'An error occurred: $e',
        }, title: 'Restore');
      }
    }
  }

  void _showBackupRestoreResult(
    Map<String, dynamic> result, {
    required String title,
  }) {
    final success = result['success'] == true;
    final counts = (result['counts'] as Map?) ?? {};
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title ${success ? 'Successful' : 'Failed'}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result['message'] ?? '', style: GoogleFonts.inter()),
            if (counts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Categories: ${counts['categories'] ?? '-'}',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              Text(
                'Fields: ${counts['fields'] ?? '-'}',
                style: GoogleFonts.inter(fontSize: 12),
              ),
              Text(
                'Items: ${counts['items'] ?? '-'}',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: const Color(0xFF5A67D8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportCSVDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Import CSV',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import password data from a CSV file.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CSV Format:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• File name = Category name\n• First row = Field names\n• First column = Item names\n• Duplicate items will be updated',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isImporting
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _performImportCSV();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A67D8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Import',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performImportCSV() async {
    setState(() {
      _isImporting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Importing CSV file...',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );

    try {
      final result = await _csvService.importCSV();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      setState(() {
        _isImporting = false;
      });

      // Show result dialog
      if (mounted) {
        _showImportResultDialog(result);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      setState(() {
        _isImporting = false;
      });

      // Show error dialog
      if (mounted) {
        _showErrorDialog(
          'Import Failed',
          'Failed to import CSV file: ${e.toString()}',
        );
      }
    }
  }

  void _showImportResultDialog(Map<String, dynamic> result) {
    final bool success = result['success'] ?? false;
    final String message = result['message'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                success ? 'Import Successful' : 'Import Failed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
            if (success) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result['categoryName'] != null)
                      Text(
                        'Category: ${result['categoryName']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    if (result['importedCount'] != null)
                      Text(
                        'New items: ${result['importedCount']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    if (result['updatedCount'] != null)
                      Text(
                        'Updated items: ${result['updatedCount']}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
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

  void _showExportCSVDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Export CSV',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how you want to export your data.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Options:',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Single file (CSV): All categories combined into one file\n  Format: Category, Item Name, Field Name, Field Value\n\n• Split files (ZIP): One CSV per category inside a ZIP\n  Format per file: Name + each field as columns\n• Empty categories will be skipped',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performExportCSV(mode: _ExportMode.single);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A67D8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Single file (CSV)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performExportCSV(mode: _ExportMode.split);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Split files (ZIP)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performExportCSV({required _ExportMode mode}) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
                ),
                const SizedBox(height: 16),
                Text(
                  mode == _ExportMode.single
                      ? 'Exporting CSV file...'
                      : 'Exporting ZIP file...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Perform export
      final result = mode == _ExportMode.single
          ? await _csvService.exportAllCategories()
          : await _csvService.exportAllCategoriesSplit();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (result['success']) {
        // Show success dialog
        _showExportResultDialog(result);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to export CSV files',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to export CSV files: ${e.toString()}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showExportResultDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Export Successful',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ?? 'Export completed successfully',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result['fileName'] != null)
                    Text(
                      'File: ${result['fileName']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  if (result['fileType'] == 'zip' &&
                      result['fileCount'] != null)
                    Text(
                      'Files in ZIP: ${result['fileCount']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  if (result['totalItemsExported'] != null)
                    Text(
                      'Total items: ${result['totalItemsExported']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  if (result['exportedCategories'] != null &&
                      (result['exportedCategories'] as List).isNotEmpty)
                    Text(
                      'Categories: ${(result['exportedCategories'] as List).join(', ')}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.green[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
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

  // Sync to Cloud Dialog and Functions
  void _showSyncToCloudDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Sync to Google Drive',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an action:',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              if (!_googleDriveService.isSignedIn) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _signInToGoogleDrive();
                    },
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: Text(
                      'Sign in to Google Drive',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A67D8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Signed in as: \${_googleDriveService.userEmail}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _uploadBackupToGoogleDrive();
                    },
                    icon: const Icon(Icons.cloud_upload, color: Colors.white),
                    label: Text(
                      'Upload Backup',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A67D8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCloudBackupsDialog();
                    },
                    icon: const Icon(Icons.cloud_download, color: Colors.white),
                    label: Text(
                      'Download Backup',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _signOutFromGoogleDrive();
                    },
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInToGoogleDrive() async {
    try {
      final result = await _googleDriveService.signIn();
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully signed in to Google Drive\nEmail: ${result['email']}',
              ),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Show detailed error message with troubleshooting
          _showDetailedErrorDialog(result);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _signOutFromGoogleDrive() async {
    try {
      await _googleDriveService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signed out from Google Drive'),
            backgroundColor: Colors.grey[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: \$e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _uploadBackupToGoogleDrive() async {
    final passwordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Upload Backup to Google Drive',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter your master password to create and upload backup:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF5A67D8)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _performUploadBackup(passwordController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A67D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Upload',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performUploadBackup(String password) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Creating and uploading backup...',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );

    try {
      // First create a local backup
      final backupResult = await _backupService.createBackup(
        password: password,
        onProgress: (message) {
          // Progress updates handled internally
        },
      );

      if (backupResult['success'] == true && backupResult['filePath'] != null) {
        // Upload to Google Drive
        final uploadResult = await _googleDriveService.uploadBackupFile(
          backupResult['filePath'],
        );

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show result
        if (mounted) {
          _showCloudBackupResult(uploadResult, title: 'Upload Backup');
        }
      } else {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          _showCloudBackupResult({
            'success': false,
            'message': backupResult['message'] ?? 'Failed to create backup',
          }, title: 'Upload Backup');
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showCloudBackupResult({
          'success': false,
          'message': 'An error occurred: \$e',
        }, title: 'Upload Backup');
      }
    }
  }

  void _showCloudBackupsDialog() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading backups from Google Drive...',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );

    try {
      final backups = await _googleDriveService.listBackupFiles();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        _showBackupListDialog(backups);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading backups: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _showBackupListDialog(List<Map<String, dynamic>> backups) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Google Drive Backups',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: backups.isEmpty
                ? Center(
                    child: Text(
                      'No backups found in Google Drive',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      final createdTime = backup['createdTime'] != null
                          ? DateTime.parse(backup['createdTime']).toLocal()
                          : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            backup['name'] ?? 'Unknown',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            createdTime != null
                                ? 'Created: ${createdTime.day}/${createdTime.month}/${createdTime.year} ${createdTime.hour}:${createdTime.minute.toString().padLeft(2, '0')}'
                                : 'Unknown date',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Color(0xFF5A67D8),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _downloadBackupFromCloud(backup);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadBackupFromCloud(Map<String, dynamic> backup) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
              ),
              const SizedBox(height: 16),
              Text(
                'Downloading and restoring backup...',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );

      // Download file from Google Drive
      final downloadResult = await _googleDriveService.downloadBackupFile(
        backup['id'],
        '/temp/downloaded_wallet.crypt',
      );

      if (downloadResult['success'] == true) {
        // Read the downloaded file
        final file = File(downloadResult['filePath']);
        final fileBytes = await file.readAsBytes();

        // Parse the backup to check if it's automatic backup
        final backupData =
            jsonDecode(utf8.decode(fileBytes)) as Map<String, dynamic>;
        final isAutoBackup = backupData['auto_backup'] == true;

        if (isAutoBackup) {
          // For automatic backup, restore without password
          final restoreResult = await _backupService.restoreBackup(
            fileBytes: fileBytes,
            password: '', // Empty password for auto backup
            mode: 'replace', // Replace existing data
            onProgress: (message) {
              print('Restore progress: $message');
            },
          );

          // Close loading dialog
          if (mounted) Navigator.pop(context);

          // Show result
          if (mounted) {
            _showCloudBackupResult(restoreResult, title: 'Restore Backup');
          }
        } else {
          // Close loading dialog first for regular backup
          if (mounted) Navigator.pop(context);

          // For regular backup, ask for password
          _showPasswordPromptForRestore(fileBytes);
        }

        // Clean up temp file
        try {
          await file.delete();
        } catch (_) {}
      } else {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(downloadResult['message'] ?? 'Download failed'),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading backup: $e'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPasswordPromptForRestore(Uint8List fileBytes) {
    final passwordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Enter Password',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the password used to create this backup:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF5A67D8)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                    ),
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (passwordController.text.isNotEmpty) {
                      Navigator.pop(context);
                      await _performRestoreWithPassword(
                        fileBytes,
                        passwordController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A67D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Restore',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performRestoreWithPassword(
    Uint8List fileBytes,
    String password,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
              ),
              const SizedBox(height: 16),
              Text(
                'Restoring backup...',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );

      final restoreResult = await _backupService.restoreBackup(
        fileBytes: fileBytes,
        password: password,
        mode: 'replace',
        onProgress: (message) {
          print('Restore progress: $message');
        },
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show result
      if (mounted) {
        _showCloudBackupResult(restoreResult, title: 'Restore Backup');
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restoring backup: $e'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCloudBackupResult(
    Map<String, dynamic> result, {
    required String title,
  }) {
    final success = result['success'] == true;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['message'] ??
                  (success
                      ? 'Operation completed successfully'
                      : 'Operation failed'),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
            ),
            if (success && result['fileName'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'File: ${result['fileName']}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A67D8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedErrorDialog(Map<String, dynamic> result) {
    String title = 'Google Drive Sign-In Error';
    String message = result['message'] ?? 'Unknown error occurred';
    String errorCode = result['error'] ?? 'UNKNOWN';
    List<Widget> troubleshootingSteps = [];

    // Add specific troubleshooting based on error code
    if (errorCode == 'DEVELOPER_ERROR') {
      title = 'Configuration Error (Code 10)';
      troubleshootingSteps = [
        Text(
          'Configuration checklist:',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        SizedBox(height: 6),
        Text(
          '• SHA-1 fingerprint added to Google Console',
          style: GoogleFonts.inter(fontSize: 11),
        ),
        Text(
          '• Package: com.example.password_manager_simple',
          style: GoogleFonts.inter(fontSize: 11),
        ),
        Text(
          '• OAuth client configured for Android',
          style: GoogleFonts.inter(fontSize: 11),
        ),
        Text(
          '• google-services.json in android/app/',
          style: GoogleFonts.inter(fontSize: 11),
        ),
        SizedBox(height: 6),
        Text(
          'Get SHA-1: cd android && gradlew.bat signingReport',
          style: GoogleFonts.firaCode(fontSize: 9, color: Colors.grey[600]),
        ),
      ];
    } else if (errorCode == 'USER_CANCELLED') {
      title = 'Sign-In Cancelled';
      message =
          'You cancelled the sign-in process. Please try again to use Google Drive features.';
    } else if (errorCode == 'NETWORK_ERROR') {
      title = 'Network Error';
      troubleshootingSteps = [
        Text(
          '• Check internet connection',
          style: GoogleFonts.inter(fontSize: 11),
        ),
        Text(
          '• Try again in a few moments',
          style: GoogleFonts.inter(fontSize: 11),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (troubleshootingSteps.isNotEmpty) ...[
                    SizedBox(height: 16),
                    ...troubleshootingSteps,
                  ],
                  if (result['details'] != null) ...[
                    SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        'Technical Details',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Error Code: $errorCode\n'
                            'Details: ${result['details']}',
                            style: GoogleFonts.firaCode(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (errorCode == 'DEVELOPER_ERROR') ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSetupGuideDialog();
                },
                child: Text(
                  'View Setup Guide',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Color(0xFF5A67D8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            if (errorCode != 'USER_CANCELLED')
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _signInToGoogleDrive();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5A67D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSetupGuideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Color(0xFF5A67D8), size: 24),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Google Drive Setup Guide',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A67D8),
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To use Google Drive backup, you need to:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSetupStep(
                    '1',
                    'Create Google Cloud Project',
                    'Go to console.cloud.google.com and create a new project',
                  ),
                  _buildSetupStep(
                    '2',
                    'Enable Google Drive API',
                    'In APIs & Services → Library, search and enable Google Drive API',
                  ),
                  _buildSetupStep(
                    '3',
                    'Get SHA-1 Fingerprint',
                    'Run: cd android && gradlew.bat signingReport',
                  ),
                  _buildSetupStep(
                    '4',
                    'Configure OAuth Consent',
                    'Set up OAuth consent screen with your app information',
                  ),
                  _buildSetupStep(
                    '5',
                    'Create Android OAuth Client',
                    'Package: com.example.password_manager_simple\nAdd your SHA-1 fingerprint',
                  ),
                  _buildSetupStep(
                    '6',
                    'Download google-services.json',
                    'Place the file in android/app/ directory',
                  ),
                  _buildSetupStep(
                    '7',
                    'Enable Google Services Plugin',
                    'Uncomment the plugin in android/app/build.gradle.kts',
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Detailed instructions are available in GOOGLE_DRIVE_SETUP.md file',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _signInToGoogleDrive();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5A67D8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSetupStep(String stepNumber, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFF5A67D8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Automatic Cloud Backup Function
  Future<void> _performAutomaticCloudBackup() async {
    try {
      // First check if user is signed in to Google Drive
      if (!_googleDriveService.isSignedIn) {
        // Show signing in message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signing in to Google Drive...'),
            backgroundColor: Colors.blue[600],
            duration: Duration(seconds: 2),
          ),
        );

        // Attempt to sign in automatically
        final signInResult = await _googleDriveService.signIn();
        if (signInResult['success'] != true) {
          // Show error if sign in failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please sign in to Google Drive first in Settings'),
              backgroundColor: Colors.orange[600],
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Sign In',
                textColor: Colors.white,
                onPressed: () {
                  _showSyncToCloudDialog();
                },
              ),
            ),
          );
          return;
        }
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
              ),
              const SizedBox(height: 16),
              Text(
                'Creating and uploading backup...',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );

      // Create automatic backup without asking for password
      final backupResult = await _createAutomaticBackup();

      if (backupResult['success'] == true && backupResult['fileData'] != null) {
        // Upload to Google Drive using the new method for automatic backups
        final uploadResult = await _googleDriveService.uploadBackupData(
          fileData: backupResult['fileData'],
          fileName: backupResult['fileName'],
        );

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Show result
        if (mounted) {
          if (uploadResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backup successfully uploaded to Google Drive!'),
                backgroundColor: Colors.green[600],
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uploadResult['message'] ?? 'Upload failed'),
                backgroundColor: Colors.red[600],
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                backupResult['message'] ?? 'Failed to create backup',
              ),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Create automatic backup without password prompt
  Future<Map<String, dynamic>> _createAutomaticBackup() async {
    try {
      final db = await _databaseHelper.database;
      final categories = await db.query('categories');
      final fields = await db.query('fields');
      final items = await db.query('password_items');

      // Build lightweight JSON payload (without password hash for automatic backup)
      final backupData = {
        'auto_backup': true, // Flag to indicate this is an automatic backup
        'data': {
          'version': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'categories': categories,
          'fields': fields,
          'password_items': items,
        },
      };

      // Create a simple fixed filename
      const fileName = 'wallet.crypt';

      // For automatic backup, we create the file data in memory
      final jsonBytes = utf8.encode(jsonEncode(backupData));

      // Create a temporary file path (this will be handled by the Google Drive service)
      const tempPath = '/temp/wallet.crypt';

      return {
        'success': true,
        'message': 'Automatic backup created successfully',
        'filePath': tempPath,
        'fileData': jsonBytes, // Include the actual file data
        'fileName': fileName,
        'counts': {
          'categories': categories.length,
          'fields': fields.length,
          'items': items.length,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Error creating backup: $e'};
    }
  }
}

enum _ExportMode { single, split }
