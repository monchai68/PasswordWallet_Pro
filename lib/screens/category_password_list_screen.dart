import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';
import 'add_new_item_screen.dart';
import 'item_detail_screen.dart';

class CategoryPasswordListScreen extends StatefulWidget {
  final String categoryName;
  final int passwordCount;
  final VoidCallback? onCountChanged; // Add callback for count changes

  const CategoryPasswordListScreen({
    super.key,
    required this.categoryName,
    required this.passwordCount,
    this.onCountChanged,
  });

  @override
  State<CategoryPasswordListScreen> createState() =>
      _CategoryPasswordListScreenState();
}

class _CategoryPasswordListScreenState
    extends State<CategoryPasswordListScreen> {
  final CategoryService _categoryService = CategoryService();
  List<PasswordItemModel> passwordItems = [];
  List<PasswordItemModel> filteredPasswordItems = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _toggleFavorite(PasswordItemModel item) async {
    final originalFav = item.isFavorite;
    final updatedItem = item.copyWith(isFavorite: !originalFav);

    // Replace in both lists (immutable update)
    void _applyItem(PasswordItemModel newItem) {
      final i1 = passwordItems.indexWhere((e) => e.id == newItem.id);
      if (i1 != -1) passwordItems[i1] = newItem;
      final i2 = filteredPasswordItems.indexWhere((e) => e.id == newItem.id);
      if (i2 != -1) filteredPasswordItems[i2] = newItem;
    }

    setState(() {
      _applyItem(updatedItem);
    });

    final success = await _categoryService.toggleFavorite(
      item.id!,
      updatedItem.isFavorite,
    );
    if (!success && mounted) {
      // rollback
      setState(() {
        _applyItem(item.copyWith(isFavorite: originalFav));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    }
  }

  // Get category info for the new item screen
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
    // You can customize colors for different categories
    return const Color(0xFF6B73FF);
  }

  @override
  void initState() {
    super.initState();
    _loadPasswordItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredPasswordItems = List.from(passwordItems);
      } else {
        filteredPasswordItems = passwordItems.where((item) {
          // Search in item name
          if (item.itemName.toLowerCase().contains(query)) {
            return true;
          }

          // Search in field values
          for (var fieldValue in item.fieldValues.values) {
            if (fieldValue.toLowerCase().contains(query)) {
              return true;
            }
          }

          return false;
        }).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _searchController.clear();
        filteredPasswordItems = List.from(passwordItems);
      }
    });
  }

  Future<void> _loadPasswordItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final items = await _categoryService.getPasswordItems(
        widget.categoryName,
      );
      setState(() {
        passwordItems = items;
        filteredPasswordItems = List.from(items);
        isLoading = false;
      });

      // Notify parent about count change
      if (widget.onCountChanged != null) {
        widget.onCountChanged!();
      }
    } catch (e) {
      print('Error loading password items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                widget.categoryName,
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
          onPressed: () {
            if (isSearching) {
              _toggleSearch();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5A67D8)),
            )
          : filteredPasswordItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSearching ? Icons.search_off : Icons.lock_outline,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSearching ? 'No items found' : 'No items yet',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSearching
                        ? 'Try different search terms'
                        : 'Tap + to add your first item',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(0),
              itemCount: filteredPasswordItems.length,
              separatorBuilder: (context, index) => const Divider(
                color: Colors.white24,
                height: 1,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                return _buildPasswordItem(filteredPasswordItems[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewItemScreen(
                categoryName: widget.categoryName,
                categoryIcon: _getCategoryIcon(widget.categoryName),
                categoryColor: _getCategoryColor(widget.categoryName),
              ),
            ),
          );

          // Refresh the list if item was added successfully
          if (result == true) {
            _loadPasswordItems();
          }
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildPasswordItem(PasswordItemModel passwordItem) {
    return Container(
      key: ValueKey(passwordItem.id),
      color: Colors.white,
      child: ListTile(
        title: Text(
          passwordItem.itemName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _toggleFavorite(passwordItem),
          icon: Icon(
            passwordItem.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: passwordItem.isFavorite
                ? Colors.red
                : Colors.grey.withOpacity(0.68),
            size: 24,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          // Navigate to item detail screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                item: passwordItem,
                categoryName: widget.categoryName,
                onItemUpdated: () {
                  _loadPasswordItems(); // Refresh list when item is updated
                },
                onItemDeleted: () {
                  _loadPasswordItems(); // Refresh list when item is deleted
                },
              ),
            ),
          );

          // Refresh the list if changes were made
          if (result == true) {
            _loadPasswordItems();
          }
        },
      ),
    );
  }
}
