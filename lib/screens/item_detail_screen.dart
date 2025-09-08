import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/field_models.dart';
import '../services/category_service.dart';
import 'add_new_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final PasswordItemModel item;
  final String categoryName;
  final VoidCallback? onItemUpdated;
  final VoidCallback? onItemDeleted;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.categoryName,
    this.onItemUpdated,
    this.onItemDeleted,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final CategoryService _categoryService = CategoryService();
  late PasswordItemModel currentItem;
  Map<String, bool> visibilityStates = {};
  List<FieldItem> categoryFields =
      []; // Add this to store category field structure
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCategoryFields();
    await _migrateFieldNames(); // Migrate old field names if needed
    _initializeVisibilityStates();
  }

  Future<void> _loadCategoryFields() async {
    try {
      categoryFields = await _categoryService.loadFields(widget.categoryName);
      // Sort by order (no longer filter by visibility)
      categoryFields = categoryFields
        ..sort((a, b) => a.order.compareTo(b.order));
      setState(() {});
    } catch (e) {
      print('Error loading category fields: $e');
    }
  }

  void _initializeVisibilityStates() {
    // Initialize visibility states based on field mask settings
    for (FieldItem field in categoryFields) {
      if (field.isMasked) {
        visibilityStates[field.name] = false; // Start hidden for masked fields
      } else {
        visibilityStates[field.name] =
            true; // Start visible for non-masked fields
      }
    }

    // For backward compatibility, also check field names
    for (String fieldName in currentItem.fieldValues.keys) {
      if (!visibilityStates.containsKey(fieldName)) {
        if (fieldName.toLowerCase().contains('password') ||
            fieldName.toLowerCase().contains('pin') ||
            fieldName.toLowerCase().contains('secret')) {
          visibilityStates[fieldName] = false;
        } else {
          visibilityStates[fieldName] = true;
        }
      }
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'App':
        return Icons.apps;
      case 'Bank':
        return Icons.account_balance;
      case 'Broker':
        return Icons.home;
      case 'Computer Logins':
        return Icons.computer;
      case 'Credit cards':
        return Icons.credit_card;
      case 'Email Accounts':
        return Icons.email;
      case 'My Cards':
        return Icons.person;
      case 'Web Accounts':
        return Icons.language;
      default:
        return Icons.folder;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'App':
        return const Color(0xFF6B73FF);
      case 'Bank':
        return const Color(0xFF28A745);
      case 'Broker':
        return const Color(0xFF17A2B8);
      case 'Computer Logins':
        return const Color(0xFF6F42C1);
      case 'Credit cards':
        return const Color(0xFFDC3545);
      case 'Email Accounts':
        return const Color(0xFFFD7E14);
      case 'My Cards':
        return const Color(0xFF20C997);
      case 'Web Accounts':
        return const Color(0xFF007BFF);
      default:
        return const Color(0xFF6B73FF);
    }
  }

  void _toggleVisibility(String fieldName) {
    setState(() {
      visibilityStates[fieldName] = !visibilityStates[fieldName]!;
    });
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$fieldName copied to clipboard',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5A67D8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _editItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewItemScreen(
          categoryName: widget.categoryName,
          categoryIcon: _getCategoryIcon(widget.categoryName),
          categoryColor: _getCategoryColor(widget.categoryName),
          editingItem: currentItem,
        ),
      ),
    );

    if (result == true) {
      // Refresh the item data
      await _refreshItemData();
      if (widget.onItemUpdated != null) {
        widget.onItemUpdated!();
      }
    }
  }

  Future<void> _refreshItemData() async {
    if (currentItem.id == null) return;

    try {
      final items = await _categoryService.getPasswordItems(
        widget.categoryName,
      );
      final updatedItem = items.firstWhere(
        (item) => item.id == currentItem.id,
        orElse: () => currentItem,
      );

      // Reload category fields in case they changed
      await _loadCategoryFields();

      setState(() {
        currentItem = updatedItem;
      });
    } catch (e) {
      print('Error refreshing item data: $e');
    }
  }

  // Helper method to migrate old field names to new ones
  Future<void> _migrateFieldNames() async {
    if (currentItem.id == null) return;

    bool hasChanges = false;
    Map<String, String> updatedFieldValues = Map.from(currentItem.fieldValues);

    // Check if any category fields have different names than stored data
    for (FieldItem field in categoryFields) {
      String currentValue = _getFieldValue(field.name);
      if (currentValue.isNotEmpty &&
          !currentItem.fieldValues.containsKey(field.name)) {
        // Found data under old field name, migrate it
        updatedFieldValues[field.name] = currentValue;
        hasChanges = true;

        // Remove old field names that mapped to this new one
        Map<String, List<String>> fieldMappings = {
          'Name': ['name', 'title', 'item_name'],
          'Login': ['login', 'username', 'user', 'email'],
          'Password': ['password', 'pass', 'pwd'],
          'Email': ['email', 'e-mail', 'mail'],
          'Note': ['note', 'notes', 'description', 'desc'],
          'URL': ['url', 'website', 'link'],
          'Phone': ['phone', 'telephone', 'mobile'],
        };

        if (fieldMappings.containsKey(field.name)) {
          for (String oldName in fieldMappings[field.name]!) {
            if (updatedFieldValues.containsKey(oldName) &&
                oldName != field.name) {
              updatedFieldValues.remove(oldName);
            }
          }
        }
      }
    }

    // Save migrated data if changes were made
    if (hasChanges) {
      final migratedItem = PasswordItemModel(
        id: currentItem.id,
        categoryId: currentItem.categoryId,
        categoryName: currentItem.categoryName,
        itemName: currentItem.itemName,
        fieldValues: updatedFieldValues,
        createdAt: currentItem.createdAt,
        updatedAt: DateTime.now(),
      );

      await _categoryService.savePasswordItem(migratedItem);
      setState(() {
        currentItem = migratedItem;
      });
    }
  }

  String _getFieldValue(String currentFieldName) {
    // First try the current field name
    if (currentItem.fieldValues.containsKey(currentFieldName)) {
      return currentItem.fieldValues[currentFieldName] ?? '';
    }

    // If not found, try common field name mappings
    Map<String, List<String>> fieldMappings = {
      'Name': ['name', 'title', 'item_name'],
      'Login': ['login', 'username', 'user', 'email'],
      'Password': ['password', 'pass', 'pwd'],
      'Email': ['email', 'e-mail', 'mail'],
      'Note': ['note', 'notes', 'description', 'desc'],
      'URL': ['url', 'website', 'link'],
      'Phone': ['phone', 'telephone', 'mobile'],
    };

    if (fieldMappings.containsKey(currentFieldName)) {
      for (String alternativeName in fieldMappings[currentFieldName]!) {
        if (currentItem.fieldValues.containsKey(alternativeName)) {
          return currentItem.fieldValues[alternativeName] ?? '';
        }
      }
    }

    return '';
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3748),
        title: Text(
          'Delete Item',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${currentItem.itemName}"? This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isLoading = true;
      });

      try {
        await _categoryService.deletePasswordItem(currentItem.id!);
        if (widget.onItemDeleted != null) {
          widget.onItemDeleted!();
        }
        Navigator.pop(context, true); // Return to previous screen
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting item: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, // ลดขนาดจาก 40 เป็น 36
              height: 36,
              decoration: BoxDecoration(
                color: _getCategoryColor(widget.categoryName),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(widget.categoryName),
                color: Colors.white,
                size: 18, // ลดขนาดไอคอนจาก 20 เป็น 18
              ),
            ),
            const SizedBox(width: 10), // ลดระยะห่างจาก 12 เป็น 10
            Expanded(
              child: Text(
                currentItem.itemName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16, // ลดจาก 18 เป็น 16
                  fontWeight: FontWeight.bold,
                  height: 1.1, // เพิ่ม line height เพื่อลดความสูง
                ),
                maxLines: 1, // จำกัดให้แสดงแค่ 1 บรรทัด
                overflow: TextOverflow.ellipsis, // ตัดด้วย ...
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5A67D8),
        elevation: 0,
        toolbarHeight: 56, // กำหนดความสูงของ AppBar ให้ชัดเจน
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 22,
          ), // ลดขนาดไอคอน
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 22,
            ), // ลดขนาดไอคอน
            onPressed: isLoading ? null : _deleteItem,
            padding: const EdgeInsets.all(8), // ลด padding
          ),
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 22,
            ), // ลดขนาดไอคอน
            onPressed: isLoading ? null : _editItem,
            padding: const EdgeInsets.all(8), // ลด padding
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A67D8), Color(0xFF1a1a1a)],
            stops: [0.0, 0.3],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF5A67D8)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Item details card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3748).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Build field rows using category structure
                          ...categoryFields.map((field) {
                            final value = _getFieldValue(field.name);
                            // Show field even if empty (with placeholder) for new fields
                            return _buildFieldRow(field.name, value);
                          }),

                          if (categoryFields.isNotEmpty)
                            const SizedBox(height: 10),

                          // Modified date with better styling
                          if (currentItem.updatedAt != null)
                            Center(
                              child: Text(
                                'Modified: ${_formatDate(currentItem.updatedAt!)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 14,
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
    );
  }

  Widget _buildFieldRow(String fieldName, String value) {
    // Find field configuration for masking
    final fieldConfig = categoryFields.firstWhere(
      (field) => field.name == fieldName,
      orElse: () => FieldItem(
        name: fieldName,
        isVisible: true,
        isRequired: false,
        isMasked:
            fieldName.toLowerCase().contains('password') ||
            fieldName.toLowerCase().contains('pin') ||
            fieldName.toLowerCase().contains('secret'),
        order: 0,
      ),
    );

    final isMasked = fieldConfig.isMasked;
    final isVisible = visibilityStates[fieldName] ?? true;
    final isEmpty = value.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field name
          SizedBox(
            width: 100,
            child: Text(
              fieldName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Field value container
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isEmpty
                        ? null
                        : () => _copyToClipboard(value, fieldName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isEmpty
                            ? '(No data)'
                            : (isMasked && !isVisible
                                  ? '*' * value.length
                                  : value),
                        style: GoogleFonts.inter(
                          color: isEmpty ? Colors.white38 : Colors.white70,
                          fontSize: 16,
                          fontStyle: isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ),
                ),

                // Visibility toggle for masked fields
                if (isMasked && !isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white60,
                        size: 20,
                      ),
                      onPressed: () => _toggleVisibility(fieldName),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
