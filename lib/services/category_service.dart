import '../database/database_helper.dart';
import '../models/field_models.dart';

class CategoryService {
  final DatabaseHelper _db = DatabaseHelper();

  // Get category ID by name
  Future<int> getCategoryId(String categoryName) async {
    return await _db.getCategoryId(categoryName);
  }

  // Load fields for a category
  Future<List<FieldItem>> loadFields(String categoryName) async {
    try {
      int categoryId = await getCategoryId(categoryName);
      List<Map<String, dynamic>> fieldMaps = await _db.getFields(categoryId);

      return fieldMaps.map((map) {
        FieldModel model = FieldModel.fromMap(map);
        return FieldItem.fromModel(model);
      }).toList();
    } catch (e) {
      print('Error loading fields: $e');
      return [];
    }
  }

  // Save a field
  Future<bool> saveField(FieldItem field, String categoryName) async {
    try {
      int categoryId = await getCategoryId(categoryName);
      FieldModel model = field.toModel(categoryId);

      if (field.id == null) {
        // Insert new field
        int id = await _db.insertField(model.toMap());
        field.id = id;
      } else {
        // Update existing field
        await _db.updateField(field.id!, model.toMap());
      }
      return true;
    } catch (e) {
      print('Error saving field: $e');
      return false;
    }
  }

  // Delete a field
  Future<bool> deleteField(FieldItem field) async {
    try {
      if (field.id != null) {
        await _db.deleteField(field.id!);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting field: $e');
      return false;
    }
  }

  // Update field order
  Future<bool> updateFieldOrder(
    List<FieldItem> fields,
    String categoryName,
  ) async {
    try {
      int categoryId = await getCategoryId(categoryName);

      List<Map<String, dynamic>> fieldMaps = fields.map((field) {
        return {
          'id': field.id,
          'category_id': categoryId,
          'order_index': field.order,
        };
      }).toList();

      await _db.updateFieldOrder(fieldMaps);
      return true;
    } catch (e) {
      print('Error updating field order: $e');
      return false;
    }
  }

  // Update category name
  Future<bool> updateCategoryName(String oldName, String newName) async {
    try {
      int categoryId = await getCategoryId(oldName);
      await _db.updateCategory(categoryId, newName);
      return true;
    } catch (e) {
      print('Error updating category name: $e');
      return false;
    }
  }

  // Update category with name and icon
  Future<bool> updateCategoryDetails(
    String oldName,
    String newName,
    int iconCodePoint,
    int colorValue,
  ) async {
    try {
      int categoryId = await getCategoryId(oldName);
      await _db.updateCategory(
        categoryId,
        newName,
        iconCodePoint: iconCodePoint,
        colorValue: colorValue,
      );
      return true;
    } catch (e) {
      print('Error updating category details: $e');
      return false;
    }
  }

  // Create new category
  Future<bool> createCategory(
    String categoryName, {
    int iconCodePoint = 0xe2bc,
  }) async {
    try {
      await _db.insertCategory(categoryName, iconCodePoint: iconCodePoint);
      return true;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryName) async {
    try {
      int categoryId = await getCategoryId(categoryName);
      await _db.deleteCategory(categoryId);
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // Get all categories
  Future<List<String>> getAllCategories() async {
    try {
      List<Map<String, dynamic>> categories = await _db.getAllCategories();
      return categories.map((cat) => cat['name'] as String).toList();
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }

  // Get all categories with details
  Future<List<Map<String, dynamic>>> getAllCategoriesWithDetails() async {
    try {
      return await _db.getAllCategories();
    } catch (e) {
      print('Error getting all categories with details: $e');
      return [];
    }
  }

  // Save a password item
  Future<bool> savePasswordItem(PasswordItemModel item) async {
    try {
      // First get the category to find its ID
      List<Map<String, dynamic>> categories = await _db.getCategories();
      int? categoryId;

      for (var category in categories) {
        if (category['name'] == item.categoryName) {
          categoryId = category['id'];
          break;
        }
      }

      if (categoryId == null) {
        print('Category not found: ${item.categoryName}');
        return false;
      }

      // Create a new item with categoryId set
      PasswordItemModel itemWithCategoryId = PasswordItemModel(
        id: item.id,
        categoryId: categoryId,
        categoryName: item.categoryName,
        itemName: item.itemName,
        fieldValues: item.fieldValues,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
      );

      Map<String, dynamic> itemMap = itemWithCategoryId.toMap();

      if (item.id == null) {
        // Insert new item
        await _db.insertPasswordItem(itemMap);
      } else {
        // Update existing item
        await _db.updatePasswordItem(item.id!, itemMap);
      }
      return true;
    } catch (e) {
      print('Error saving password item: $e');
      return false;
    }
  }

  // Get password items for a category
  Future<List<PasswordItemModel>> getPasswordItems(String categoryName) async {
    try {
      // First get the category to find its ID
      List<Map<String, dynamic>> categories = await _db.getCategories();
      int? categoryId;

      for (var category in categories) {
        if (category['name'] == categoryName) {
          categoryId = category['id'];
          break;
        }
      }

      if (categoryId == null) {
        print('Category not found: $categoryName');
        return [];
      }

      List<Map<String, dynamic>> itemMaps = await _db.getPasswordItems(
        categoryId,
      );
      return itemMaps.map((map) => PasswordItemModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting password items: $e');
      return [];
    }
  }

  // Delete a password item
  Future<bool> deletePasswordItem(int itemId) async {
    try {
      await _db.deletePasswordItem(itemId);
      return true;
    } catch (e) {
      print('Error deleting password item: $e');
      return false;
    }
  }

  // Toggle favorite status of a password item
  Future<bool> toggleFavorite(int itemId, bool isFavorite) async {
    try {
      await _db.updateFavoriteStatus(itemId, isFavorite);
      return true;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Get all favorite items from all categories
  Future<List<PasswordItemModel>> getAllFavoriteItems() async {
    try {
      List<PasswordItemModel> allFavorites = [];

      // Get all categories first
      List<Map<String, dynamic>> categories = await _db.getCategories();

      // For each category, get favorite items
      for (var category in categories) {
        int categoryId = category['id'];
        String categoryName = category['name'];

        List<Map<String, dynamic>> itemMaps = await _db.getFavoriteItems(
          categoryId,
        );

        for (var map in itemMaps) {
          PasswordItemModel item = PasswordItemModel.fromMap(map);
          // Update categoryName since fromMap doesn't include it
          item = PasswordItemModel(
            id: item.id,
            categoryId: item.categoryId,
            categoryName: categoryName,
            itemName: item.itemName,
            fieldValues: item.fieldValues,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            isFavorite: item.isFavorite,
          );
          allFavorites.add(item);
        }
      }

      // Sort by item name
      allFavorites.sort((a, b) => a.itemName.compareTo(b.itemName));

      return allFavorites;
    } catch (e) {
      print('Error getting all favorite items: $e');
      return [];
    }
  }
}
