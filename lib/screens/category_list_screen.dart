import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';
import 'category_password_list_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
    with WidgetsBindingObserver {
  final CategoryService _categoryService = CategoryService();
  List<CategoryItem> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategories();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> categoriesData = await _categoryService
          .getAllCategoriesWithDetails();

      List<CategoryItem> loadedCategories = [];

      for (var categoryData in categoriesData) {
        // Load password items for this category to count them
        List<PasswordItemModel> passwordItems = await _categoryService
            .getPasswordItems(categoryData['name']);

        loadedCategories.add(
          CategoryItem(
            icon: IconData(
              categoryData['icon_code_point'] ?? 0xe2bc,
              fontFamily: 'MaterialIcons',
            ),
            name: categoryData['name'],
            count: passwordItems.length, // Count actual password items
            color: Color(
              categoryData['color_value'] ?? 4294945792,
            ), // Load color from database
            id: categoryData['id'],
          ),
        );
      }

      setState(() {
        categories = loadedCategories;

        // Add default categories if none exist
        if (categories.isEmpty) {
          _addDefaultCategories();
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _addDefaultCategories();
        _isLoading = false;
      });
    }
  }

  void _addDefaultCategories() {
    categories = [
      CategoryItem(
        icon: Icons.apps,
        name: 'App',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.account_balance,
        name: 'Bank',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.home,
        name: 'Broker',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.computer,
        name: 'Computer Logins',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.credit_card,
        name: 'Credit cards',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.email,
        name: 'Email Accounts',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.person,
        name: 'My Cards',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
      CategoryItem(
        icon: Icons.language,
        name: 'Web Accounts',
        count: 0,
        color: const Color(0xFF6B73FF),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          'Password Pocket - Category List',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(0),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Divider(
                color: Colors.white24,
                height: 1,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryItem(category);
              },
            ),
    );
  }

  Widget _buildCategoryItem(CategoryItem category) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, color: Colors.white, size: 28),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        trailing: Text(
          category.count.toString(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          // Navigate to category password list
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryPasswordListScreen(
                categoryName: category.name,
                passwordCount: category.count,
                onCountChanged: () {
                  // Refresh categories when count changes
                  _loadCategories();
                },
              ),
            ),
          );

          // Always refresh categories when coming back
          _loadCategories();
        },
      ),
    );
  }
}

class CategoryItem {
  final IconData icon;
  final String name;
  final int count;
  final Color color;
  final int? id;

  CategoryItem({
    required this.icon,
    required this.name,
    required this.count,
    required this.color,
    this.id,
  });
}
