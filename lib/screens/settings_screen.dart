import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';
import '../services/csv_service.dart';
import '../services/backup_service.dart';

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
}

enum _ExportMode { single, split }
