import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';

class CategoryFieldEditorScreen extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;

  const CategoryFieldEditorScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
  });

  @override
  State<CategoryFieldEditorScreen> createState() =>
      _CategoryFieldEditorScreenState();
}

class _CategoryFieldEditorScreenState extends State<CategoryFieldEditorScreen> {
  late TextEditingController categoryNameController;
  final CategoryService _categoryService = CategoryService();

  // List of fields for the category - will be loaded from database
  List<FieldItem> fields = [];
  bool isLoading = true;

  // Map to store TextEditingController for each field
  Map<int, TextEditingController> fieldControllers = {};

  // Current selected icon and color
  late IconData currentIcon;
  late Color currentColor;

  @override
  void initState() {
    super.initState();
    categoryNameController = TextEditingController(text: widget.categoryName);
    currentIcon = widget.categoryIcon;
    currentColor = const Color(0xFFFFB000); // Default orange color
    _loadCategoryData();
    _loadFields();
  }

  // Load category data including color
  Future<void> _loadCategoryData() async {
    try {
      List<Map<String, dynamic>> categories = await _categoryService
          .getAllCategoriesWithDetails();
      final categoryData = categories.firstWhere(
        (cat) => cat['name'] == widget.categoryName,
        orElse: () => {},
      );

      if (categoryData.isNotEmpty) {
        setState(() {
          currentColor = Color(categoryData['color_value'] ?? 4294945792);
        });
      }
    } catch (e) {
      print('Error loading category data: $e');
    }
  }

  // Load fields from database
  Future<void> _loadFields() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<FieldItem> loadedFields = await _categoryService.loadFields(
        widget.categoryName,
      );

      // Create TextEditingController for each field
      fieldControllers.clear();
      for (int i = 0; i < loadedFields.length; i++) {
        fieldControllers[i] = TextEditingController(text: loadedFields[i].name);
      }

      setState(() {
        fields = loadedFields;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading fields: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    categoryNameController.dispose();
    // Dispose all field controllers
    for (var controller in fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              _showDeleteCategoryDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette, color: Colors.white),
            onPressed: () {
              _showColorPickerDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: () {
              _saveChanges();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category header section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Icon',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 40),
                Text(
                  'Category Name',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showIconPickerDialog();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(currentIcon, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: TextField(
                    controller: categoryNameController,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Fields header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(width: 120), // Space for up/down arrows
                Text(
                  'Field',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                Icon(Icons.visibility_off, color: Colors.black54, size: 20),
                const SizedBox(width: 20),
                Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          // Fields list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: fields.length,
                          itemBuilder: (context, index) {
                            return _buildFieldItem(fields[index], index);
                          },
                        ),
                        // Add field button directly after fields
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _showAddFieldDialog();
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.green,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(FieldItem field, int index) {
    return Container(
      key: ValueKey(field.name + index.toString()),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Up/Down arrows for reordering
            GestureDetector(
              onTap: () {
                if (index > 0) {
                  _moveFieldUp(index);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: index > 0 ? Colors.grey[300] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: index > 0 ? Colors.grey[400]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: index > 0 ? Colors.grey[700] : Colors.grey[400],
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (index < fields.length - 1) {
                  _moveFieldDown(index);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: index < fields.length - 1
                      ? Colors.grey[300]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: index < fields.length - 1
                        ? Colors.grey[400]!
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: index < fields.length - 1
                      ? Colors.grey[700]
                      : Colors.grey[400],
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Field name
            Expanded(
              child: TextField(
                controller:
                    fieldControllers[index] ??
                    TextEditingController(text: field.name),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  field.name = value;
                  // Save change to database
                  _saveFieldChange(field);
                },
              ),
            ),
            const SizedBox(width: 16),
            // Mask checkbox (eye icon)
            GestureDetector(
              onTap: () {
                setState(() {
                  field.isMasked = !field.isMasked;
                });
                // Save change to database
                _saveFieldChange(field);
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: field.isMasked
                      ? const Color(0xFF5A67D8)
                      : Colors.white,
                ),
                child: field.isMasked
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 32),
            // Delete button
            GestureDetector(
              onTap: () {
                if (!field.isRequired) {
                  _deleteFieldFromDatabase(field, index);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot delete required field'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Icon(
                  Icons.close,
                  color: field.isRequired ? Colors.grey : Colors.red,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFieldDialog() {
    final TextEditingController fieldNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: Text(
            'Add New Field',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: fieldNameController,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter field name',
              hintStyle: GoogleFonts.inter(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A67D8)),
              ),
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
            TextButton(
              onPressed: () async {
                if (fieldNameController.text.isNotEmpty) {
                  // Check if field name contains "password" to auto-mask
                  bool shouldMask =
                      fieldNameController.text.toLowerCase().contains(
                        'password',
                      ) ||
                      fieldNameController.text.toLowerCase().contains('pass') ||
                      fieldNameController.text.toLowerCase().contains('pwd');

                  FieldItem newField = FieldItem(
                    name: fieldNameController.text,
                    isVisible: true,
                    isRequired: false,
                    isMasked: shouldMask,
                    order: fields.length + 1,
                  );

                  // Save to database
                  bool success = await _categoryService.saveField(
                    newField,
                    widget.categoryName,
                  );

                  if (success) {
                    setState(() {
                      fields.add(newField);
                      // Create controller for new field
                      fieldControllers[fields.length - 1] =
                          TextEditingController(text: newField.name);
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added field "${fieldNameController.text}"',
                        ),
                        backgroundColor: const Color(0xFF4CAF50),
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
  }

  // Reorder fields with database save
  Future<void> _reorderFields(int oldIndex, int newIndex) async {
    setState(() {
      final item = fields.removeAt(oldIndex);
      fields.insert(newIndex, item);

      // Update order numbers for all fields
      for (int i = 0; i < fields.length; i++) {
        fields[i].order = i + 1;
      }

      // Update controllers mapping
      _updateControllersMapping();
    });

    // Save order to database
    await _categoryService.updateFieldOrder(fields, widget.categoryName);
  }

  // Update controllers mapping after reordering
  void _updateControllersMapping() {
    Map<int, TextEditingController> newControllers = {};
    for (int i = 0; i < fields.length; i++) {
      // Find existing controller for this field name or create new one
      TextEditingController? existingController;
      for (var entry in fieldControllers.entries) {
        if (fieldControllers[entry.key]?.text == fields[i].name) {
          existingController = entry.value;
          break;
        }
      }
      newControllers[i] =
          existingController ?? TextEditingController(text: fields[i].name);
    }

    // Dispose old controllers that are no longer needed
    for (var controller in fieldControllers.values) {
      if (!newControllers.values.contains(controller)) {
        controller.dispose();
      }
    }

    fieldControllers = newControllers;
  }

  // Save field change to database
  Future<void> _saveFieldChange(FieldItem field) async {
    await _categoryService.saveField(field, widget.categoryName);
  }

  // Delete field from database
  Future<void> _deleteFieldFromDatabase(FieldItem field, int index) async {
    bool success = await _categoryService.deleteField(field);
    if (success) {
      setState(() {
        fields.removeAt(index);
        // Dispose and remove controller
        fieldControllers[index]?.dispose();
        fieldControllers.remove(index);

        // Reorganize controllers for remaining fields
        Map<int, TextEditingController> newControllers = {};
        for (int i = 0; i < fields.length; i++) {
          if (i < index) {
            newControllers[i] = fieldControllers[i]!;
          } else {
            newControllers[i] = fieldControllers[i + 1]!;
          }
        }
        fieldControllers = newControllers;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted field "${field.name}"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _moveFieldUp(int index) {
    if (index > 0) {
      _reorderFields(index, index - 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved "${fields[index].name}" up'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  void _moveFieldDown(int index) {
    if (index < fields.length - 1) {
      _reorderFields(index, index + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved "${fields[index].name}" down'),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  void _showDeleteCategoryDialog() {
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
            'Are you sure you want to delete "${widget.categoryName}" category and all its data?',
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
                Navigator.of(context).pop(); // Close dialog

                try {
                  // Actually delete the category from database
                  bool success = await _categoryService.deleteCategory(
                    widget.categoryName,
                  );

                  if (success) {
                    Navigator.of(
                      context,
                    ).pop(true); // Go back with success result
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted category "${widget.categoryName}"',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete category'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting category: $e'),
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

  void _saveChanges() async {
    // Save the category name change and icon change
    try {
      bool success = await _categoryService.updateCategoryDetails(
        widget.categoryName,
        categoryNameController.text,
        currentIcon.codePoint,
        currentColor.value,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved changes to "${categoryNameController.text}" category',
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.of(
          context,
        ).pop('updated'); // Send signal that data was updated
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save changes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorPickerDialog() {
    final List<Color> availableColors = [
      const Color(0xFFFFB000), // Orange
      const Color(0xFF6B73FF), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFF44336), // Red
      const Color(0xFFFF9800), // Deep Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF795548), // Brown
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a2a2a),
          title: Text(
            'Choose Color',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: availableColors.length,
              itemBuilder: (context, index) {
                final color = availableColors[index];
                final isSelected = color.value == currentColor.value;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentColor = color;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(color: Colors.white24, width: 1),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 28)
                        : null,
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

  void _showIconPickerDialog() {
    final List<IconData> availableIcons = [
      Icons.apps,
      Icons.account_balance,
      Icons.home,
      Icons.computer,
      Icons.credit_card,
      Icons.email,
      Icons.person,
      Icons.language,
      Icons.work,
      Icons.school,
      Icons.shopping_cart,
      Icons.car_rental,
      Icons.sports_esports,
      Icons.music_note,
      Icons.movie,
      Icons.restaurant,
      Icons.fitness_center,
      Icons.local_hospital,
      Icons.flight,
      Icons.hotel,
      Icons.local_library,
      Icons.pets,
      Icons.nature,
      Icons.beach_access,
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
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: availableIcons.length,
              itemBuilder: (context, index) {
                final icon = availableIcons[index];
                final isSelected = icon.codePoint == currentIcon.codePoint;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIcon = icon;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6B73FF)
                          : const Color(0xFF4a4a4a),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF6B73FF), width: 2)
                          : null,
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
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
