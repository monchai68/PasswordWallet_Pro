import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import 'category_field_editor_screen.dart';

class CategoryEditorScreen extends StatefulWidget {
  const CategoryEditorScreen({super.key});

  @override
  State<CategoryEditorScreen> createState() => _CategoryEditorScreenState();
}

class _CategoryEditorScreenState extends State<CategoryEditorScreen> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryEditorItem> categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> categoriesData = await _categoryService
          .getAllCategoriesWithDetails();

      setState(() {
        categories = categoriesData.map((categoryData) {
          return CategoryEditorItem(
            icon: IconData(
              categoryData['icon_code_point'] ?? 0xe2bc,
              fontFamily: 'MaterialIcons',
            ),
            name: categoryData['name'],
            color: Color(categoryData['color_value'] ?? 4294945792),
            id: categoryData['id'],
          );
        }).toList();

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
      CategoryEditorItem(
        icon: Icons.apps,
        name: 'App',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.account_balance,
        name: 'Bank',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.home,
        name: 'Broker',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.computer,
        name: 'Computer Logins',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.credit_card,
        name: 'Credit cards',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.email,
        name: 'Email Accounts',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.person,
        name: 'My Cards',
        color: const Color(0xFFFFB000), // Default orange color
      ),
      CategoryEditorItem(
        icon: Icons.language,
        name: 'Web Accounts',
        color: const Color(0xFFFFB000), // Default orange color
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Text(
          'Category Editor',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              _showAddCategoryDialog();
            },
          ),
        ],
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
                return _buildCategoryItem(category, index);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog();
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryEditorItem category, int index) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryFieldEditorScreen(
                      categoryName: category.name,
                      categoryIcon: category.icon,
                    ),
                  ),
                );

                // If category was deleted or updated, refresh the list
                if (result == true || result == 'updated') {
                  _loadCategories();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmDialog(category, index);
              },
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryFieldEditorScreen(
                categoryName: category.name,
                categoryIcon: category.icon,
              ),
            ),
          );

          // If category was deleted or updated, refresh the list
          if (result == true || result == 'updated') {
            _loadCategories();
          }
        },
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    IconData selectedIcon = Icons.folder;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2a2a2a),
              title: Text(
                'Add New Category',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter category name',
                      hintStyle: GoogleFonts.inter(color: Colors.white54),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF5A67D8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Icon: ',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B73FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selectedIcon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showIconPickerDialog(setDialogState, (icon) {
                            selectedIcon = icon;
                          });
                        },
                        child: const Text('Choose'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      try {
                        // Save to database
                        bool success = await _categoryService.createCategory(
                          nameController.text,
                          iconCodePoint: selectedIcon.codePoint,
                        );

                        if (success) {
                          // Reload categories from database
                          await _loadCategories();

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added category "${nameController.text}"',
                              ),
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save category'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Error adding category: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error saving category'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Add',
                    style: GoogleFonts.inter(color: const Color(0xFF5A67D8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(CategoryEditorItem category, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: Text(
            'Delete Category',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${category.name}" category?',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  bool success = await _categoryService.deleteCategory(
                    category.name,
                  );

                  if (success) {
                    // Reload categories from database
                    await _loadCategories();

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Deleted category "${category.name}"'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete category'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error deleting category: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error deleting category'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showIconPickerDialog(
    StateSetter setDialogState,
    Function(IconData) onIconSelected,
  ) {
    final List<IconData> availableIcons = [
      Icons.apps,
      Icons.account_balance,
      Icons.home,
      Icons.computer,
      Icons.credit_card,
      Icons.email,
      Icons.person,
      Icons.language,
      Icons.folder,
      Icons.work,
      Icons.shopping_cart,
      Icons.school,
      Icons.local_hospital,
      Icons.directions_car,
      Icons.flight,
      Icons.restaurant,
      Icons.sports,
      Icons.music_note,
      Icons.movie,
      Icons.games,
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: Text(
            'Choose Icon',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: availableIcons.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onIconSelected(availableIcons[index]);
                    setDialogState(() {});
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B73FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      availableIcons[index],
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryEditorItem {
  final IconData icon;
  final String name;
  final Color color;
  final int? id;

  CategoryEditorItem({
    required this.icon,
    required this.name,
    required this.color,
    this.id,
  });
}
