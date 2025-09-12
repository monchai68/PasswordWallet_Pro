import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../services/google_drive_service.dart';
import '../models/field_models.dart';
import '../database/database_helper.dart';
import 'dart:convert';
import 'category_list_screen.dart';
import 'category_editor_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final CategoryService _categoryService = CategoryService();
  final GoogleDriveService _googleDriveService = GoogleDriveService();
  int totalPasswords = 0;
  int favoritePasswords = 0;
  bool isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatistics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh statistics when app comes back to foreground
      _loadStatistics();
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get all categories
      List<Map<String, dynamic>> categoriesData = await _categoryService
          .getAllCategoriesWithDetails();

      int totalCount = 0;
      int favoriteCount = 0;

      // Count password items in each category
      for (var categoryData in categoriesData) {
        List<PasswordItemModel> passwordItems = await _categoryService
            .getPasswordItems(categoryData['name']);
        totalCount += passwordItems.length;

        // Count favorites
        favoriteCount += passwordItems.where((item) => item.isFavorite).length;
      }

      setState(() {
        totalPasswords = totalCount;
        favoritePasswords = favoriteCount;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        totalPasswords = 0;
        favoritePasswords = 0;
        isLoading = false;
      });
    }
  }

  Future<void> _performAutomaticCloudBackup() async {
    try {
      if (!_googleDriveService.isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signing in to Google Drive...'),
            backgroundColor: Colors.blue[600],
            duration: Duration(seconds: 2),
          ),
        );
        final signInResult = await _googleDriveService.signIn();
        if (signInResult['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please sign in to Google Drive first in Settings'),
              backgroundColor: Colors.orange[600],
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Sign In',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          );
          return;
        }
      }

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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
              ),
              const SizedBox(height: 16),
              Text(
                'Creating and uploading backup...',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );

      // Create automatic backup without asking for password
      final db = await _databaseHelper.database;
      final categories = await db.query('categories');
      final fields = await db.query('fields');
      final items = await db.query('password_items');
      final backupData = {
        'auto_backup': true,
        'data': {
          'version': 1,
          'createdAt': DateTime.now().toIso8601String(),
          'categories': categories,
          'fields': fields,
          'password_items': items,
        },
      };
      final jsonBytes = utf8.encode(jsonEncode(backupData));
      const fileName = 'wallet.crypt';

      final uploadResult = await _googleDriveService.uploadBackupData(
        fileData: jsonBytes,
        fileName: fileName,
      );

      if (mounted) Navigator.pop(context);

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
    } catch (e) {
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

  Future<void> _performGoogleDriveSync(String password) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2d2d2d),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 16),
            Text(
              'Syncing to Google Drive...',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );

    try {
      // Check if signed in to Google Drive
      bool isSignedIn = _googleDriveService.isSignedIn;

      if (!isSignedIn) {
        Navigator.pop(context); // Close loading dialog
        _showSignInDialog();
        return;
      }

      // Navigate to Settings screen to use existing sync functionality
      Navigator.pop(context); // Close loading dialog
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );

      // Refresh statistics when coming back
      _loadStatistics();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Sync failed: ${e.toString()}');
    }
  }

  void _showSignInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2d2d2d),
        title: Text(
          'Google Drive Sign In Required',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Please sign in to Google Drive in Settings first to enable sync.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Go to Settings',
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2d2d2d),
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          'PasswordWallet',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2d2d2d),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Upload to Cloud',
            onPressed: isLoading ? null : _performAutomaticCloudBackup,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Welcome!',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your passwords securely',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),

              // Statistics Section
              Text(
                'Statistics',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Passwords',
                      count: isLoading ? '...' : totalPasswords.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Favorites',
                      count: isLoading ? '...' : favoritePasswords.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions Section
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.category,
                    title: 'Categories',
                    subtitle: 'Organize passwords',
                    color: Colors.blue,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryListScreen(),
                        ),
                      );
                      // Refresh statistics when coming back
                      _loadStatistics();
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.edit_note,
                    title: 'Category Editor',
                    subtitle: 'Manage categories',
                    color: Colors.green,
                    onTap: () async {
                      // Navigate to category editor
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryEditorScreen(),
                        ),
                      );
                      // Refresh statistics when coming back
                      _loadStatistics();
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.favorite,
                    title: 'Favorites',
                    subtitle: 'Frequently used passwords',
                    color: Colors.red,
                    onTap: () async {
                      // Navigate to favorites screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                      // Refresh statistics when coming back
                      _loadStatistics();
                    },
                  ),
                  _buildActionCard(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'Customize app',
                    color: Colors.grey,
                    onTap: () async {
                      // Navigate to settings screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                      // Refresh statistics when coming back
                      _loadStatistics();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
