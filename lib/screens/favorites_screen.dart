import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';
import 'item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final CategoryService _categoryService = CategoryService();
  List<PasswordItemModel> favoriteItems = [];
  List<PasswordItemModel> filteredFavoriteItems = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Get category info for icons
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
    _loadFavoriteItems();
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
        filteredFavoriteItems = List.from(favoriteItems);
      } else {
        filteredFavoriteItems = favoriteItems.where((item) {
          // Search in item name
          if (item.itemName.toLowerCase().contains(query)) {
            return true;
          }

          // Search in category name
          if (item.categoryName.toLowerCase().contains(query)) {
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
        filteredFavoriteItems = List.from(favoriteItems);
      }
    });
  }

  Future<void> _loadFavoriteItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      final items = await _categoryService.getAllFavoriteItems();
      setState(() {
        favoriteItems = items;
        filteredFavoriteItems = List.from(items);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading favorite items: $e');
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
                  hintText: 'Search favorites...',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Favorites',
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
          : filteredFavoriteItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSearching ? Icons.search_off : Icons.favorite_border,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSearching ? 'No favorites found' : 'No favorites yet',
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
                        : 'Add favorites by tapping the heart icon in item lists',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(0),
              itemCount: filteredFavoriteItems.length,
              separatorBuilder: (context, index) => const Divider(
                color: Colors.white24,
                height: 1,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                return _buildFavoriteItem(filteredFavoriteItems[index]);
              },
            ),
    );
  }

  Widget _buildFavoriteItem(PasswordItemModel passwordItem) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(passwordItem.categoryName),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(passwordItem.categoryName),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          passwordItem.itemName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          passwordItem.categoryName,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: GestureDetector(
          onTap: () async {
            // Toggle favorite status
            final newFavoriteStatus = !passwordItem.isFavorite;
            final success = await _categoryService.toggleFavorite(
              passwordItem.id!,
              newFavoriteStatus,
            );

            if (success) {
              // Refresh the list to remove unfavorited items
              _loadFavoriteItems();
            }
          },
          child: Icon(Icons.favorite, color: Colors.red, size: 24),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          // Navigate to item detail screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                item: passwordItem,
                categoryName: passwordItem.categoryName,
                onItemUpdated: () {
                  _loadFavoriteItems(); // Refresh list when item is updated
                },
                onItemDeleted: () {
                  _loadFavoriteItems(); // Refresh list when item is deleted
                },
              ),
            ),
          );

          // Refresh the list if changes were made
          if (result == true) {
            _loadFavoriteItems();
          }
        },
      ),
    );
  }
}
