import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';

class AddNewItemScreen extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final PasswordItemModel? editingItem; // For editing existing items

  const AddNewItemScreen({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.editingItem,
  });

  @override
  State<AddNewItemScreen> createState() => _AddNewItemScreenState();
}

class _AddNewItemScreenState extends State<AddNewItemScreen> {
  final CategoryService _categoryService = CategoryService();
  List<FieldItem> fields = [];
  Map<String, TextEditingController> fieldControllers = {};
  bool isLoading = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFields() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<FieldItem> loadedFields = await _categoryService.loadFields(
        widget.categoryName,
      );

      // Sort by order (no longer filter by visibility)
      final sortedFields = loadedFields
        ..sort((a, b) => a.order.compareTo(b.order));

      // Create controllers for each field
      fieldControllers.clear();
      for (var field in sortedFields) {
        final controller = TextEditingController();

        // If editing an existing item, populate the field with existing data
        if (widget.editingItem != null) {
          final existingValue = widget.editingItem!.fieldValues[field.name];
          if (existingValue != null && existingValue.isNotEmpty) {
            controller.text = existingValue;
          }
        }

        fieldControllers[field.name] = controller;
      }

      setState(() {
        fields = sortedFields;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading fields: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveItem() async {
    // Validate required fields
    for (var field in fields) {
      if (field.isRequired &&
          (fieldControllers[field.name]?.text.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${field.name} is required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Check if at least the first field (usually Name) is filled
    if (fields.isNotEmpty &&
        (fieldControllers[fields[0].name]?.text.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${fields[0].name} is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Prepare data to save
      Map<String, String> fieldValues = {};
      String itemName = '';

      for (var field in fields) {
        String value = fieldControllers[field.name]?.text ?? '';
        fieldValues[field.name] = value;

        // Use the first field as the item name
        if (field == fields.first) {
          itemName = value;
        }
      }

      // Create or update password item
      PasswordItemModel passwordItem = PasswordItemModel(
        id: widget.editingItem?.id, // Include ID if editing
        categoryName: widget.categoryName,
        itemName: itemName,
        fieldValues: fieldValues,
        createdAt: widget.editingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isFavorite:
            widget.editingItem?.isFavorite ??
            false, // Preserve favorite status or default to false
      );

      // Save to database
      bool success = await _categoryService.savePasswordItem(passwordItem);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editingItem != null
                  ? 'Item updated successfully!'
                  : 'Item saved successfully!',
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );

        // Navigate back
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to save item');
      }
    } catch (e) {
      print('Error saving item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving item'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A67D8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.categoryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.categoryIcon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.editingItem != null
                    ? 'Edit ${widget.editingItem!.itemName}'
                    : widget.categoryName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveItem,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A67D8)),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      ...fields.map((field) => _buildFieldInput(field)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFieldInput(FieldItem field) {
    bool shouldObscure = field.isMasked;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: fieldControllers[field.name],
            obscureText: shouldObscure ? _obscurePassword : false,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            decoration: InputDecoration(
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A67D8), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: shouldObscure
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
            ),
            maxLines: field.name.toLowerCase().contains('note') ? 3 : 1,
          ),
        ],
      ),
    );
  }
}
