import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';
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
  int totalPasswords = 0;
  int favoritePasswords = 0;
  bool isLoading = true;

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
