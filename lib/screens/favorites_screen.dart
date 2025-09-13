import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../services/category_service.dart';
import '../models/field_models.dart';
import 'item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  List<PasswordItemModel> favoriteItems = [];
  List<PasswordItemModel> filteredFavoriteItems = [];
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  // Track rows that are animating out (fade+shrink) and their timers for safe cancellation
  final Set<int> _removingIds = {}; // ids currently fading/shrinking out
  final Map<int, Timer> _removalTimers =
      {}; // timers that will actually remove after animation

  static const _removalAnimationDuration = Duration(milliseconds: 300);

  Future<void> _toggleFavorite(PasswordItemModel item) async {
    final originalFav = item.isFavorite; // should be true on this screen
    final targetFav = !originalFav; // normally false when unfavoriting
    final updated = item.copyWith(isFavorite: targetFav);

    void _apply(PasswordItemModel newItem) {
      final i1 = favoriteItems.indexWhere((e) => e.id == newItem.id);
      if (i1 != -1) favoriteItems[i1] = newItem;
      final i2 = filteredFavoriteItems.indexWhere((e) => e.id == newItem.id);
      if (i2 != -1) filteredFavoriteItems[i2] = newItem;
    }

    // Optimistic UI: start animation instead of instant removal
    if (!targetFav) {
      final id = item.id!;
      setState(() {
        _apply(
          updated,
        ); // update model so heart reflects new state if still visible
        _removingIds.add(id);
      });

      // Schedule actual removal after animation completes
      _removalTimers[id]?.cancel();
      _removalTimers[id] = Timer(_removalAnimationDuration, () {
        if (!mounted) return;
        setState(() {
          favoriteItems.removeWhere((e) => e.id == id);
          filteredFavoriteItems.removeWhere((e) => e.id == id);
          _removingIds.remove(id);
          _removalTimers.remove(id);
        });
      });
    } else {
      // (Rare) case toggling to favorite again (not typical within favorites screen)
      setState(() => _apply(updated));
    }

    final success = await _categoryService.toggleFavorite(item.id!, targetFav);
    if (!success && mounted) {
      // Rollback: cancel any pending removal and restore item state
      final id = item.id!;
      _removalTimers[id]?.cancel();
      _removalTimers.remove(id);

      setState(() {
        _removingIds.remove(id); // stop animation
        if (targetFav == false) {
          // We attempted to remove but failed -> ensure item is back and marked favorite
          final restored = item.copyWith(isFavorite: originalFav);
          final exists = favoriteItems.any((e) => e.id == id);
          if (!exists) {
            favoriteItems.add(restored);
          }
          final existsF = filteredFavoriteItems.any((e) => e.id == id);
          if (!existsF) {
            filteredFavoriteItems.add(restored);
          }
          _apply(restored);
        } else {
          // Attempted to favorite (rare) but failed
          _apply(item.copyWith(isFavorite: originalFav));
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update favorite')),
      );
    }
  }

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
    for (final timer in _removalTimers.values) {
      timer.cancel();
    }
    _removalTimers.clear();
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
    final isRemoving =
        passwordItem.id != null && _removingIds.contains(passwordItem.id);

    final row = Container(
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
        trailing: IconButton(
          onPressed: () => _toggleFavorite(passwordItem),
          icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                item: passwordItem,
                categoryName: passwordItem.categoryName,
                onItemUpdated: () {
                  _loadFavoriteItems();
                },
                onItemDeleted: () {
                  _loadFavoriteItems();
                },
              ),
            ),
          );
          if (result == true) {
            _loadFavoriteItems();
          }
        },
      ),
    );

    return AnimatedScale(
      key: ValueKey(passwordItem.id),
      scale: isRemoving ? 0.95 : 1.0, // slight shrink while fading
      duration: _removalAnimationDuration,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isRemoving ? 0.0 : 1.0,
        duration: _removalAnimationDuration,
        curve: Curves.easeOut,
        child: row,
      ),
    );
  }
}
