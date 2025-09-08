import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(
      await getDatabasesPath(),
      'password_manager_v6.db',
    ); // Changed filename to force new database
    return await openDatabase(
      path,
      version: 6, // Increased version to include is_favorite column
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL DEFAULT 4294945792,
        created_at TEXT NOT NULL
      )
    ''');

    // Create fields table
    await db.execute('''
      CREATE TABLE fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        is_visible INTEGER NOT NULL DEFAULT 1,
        is_required INTEGER NOT NULL DEFAULT 0,
        is_masked INTEGER NOT NULL DEFAULT 0,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Create password_items table
    await db.execute('''
      CREATE TABLE password_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        field_values TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await _insertDefaultData(db);
  }

  Future<void> _insertDefaultData(Database db) async {
    // Insert default categories
    List<Map<String, dynamic>> defaultCategories = [
      {
        'name': 'App',
        'icon_code_point': 0xe037,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Bank',
        'icon_code_point': 0xe0e8,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Broker',
        'icon_code_point': 0xe318,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Computer Logins',
        'icon_code_point': 0xe30a,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Credit cards',
        'icon_code_point': 0xe25c,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Email Accounts',
        'icon_code_point': 0xe0ef,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'My Cards',
        'icon_code_point': 0xe491,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'name': 'Web Accounts',
        'icon_code_point': 0xe894,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    for (var category in defaultCategories) {
      int categoryId = await db.insert('categories', category);

      // Insert default fields for each category
      List<Map<String, dynamic>> defaultFields = [
        {
          'category_id': categoryId,
          'name': 'Name',
          'is_visible': 1,
          'is_required': 1,
          'is_masked': 0,
          'order_index': 1,
        },
        {
          'category_id': categoryId,
          'name': 'Login',
          'is_visible': 1,
          'is_required': 0,
          'is_masked': 0,
          'order_index': 2,
        },
        {
          'category_id': categoryId,
          'name': 'Password',
          'is_visible': 1,
          'is_required': 1,
          'is_masked': 1, // Password should be masked by default
          'order_index': 3,
        },
        {
          'category_id': categoryId,
          'name': 'Email',
          'is_visible': 1,
          'is_required': 0,
          'is_masked': 0,
          'order_index': 4,
        },
        {
          'category_id': categoryId,
          'name': 'Note',
          'is_visible': 1,
          'is_required': 0,
          'is_masked': 0,
          'order_index': 5,
        },
      ];

      for (var field in defaultFields) {
        await db.insert('fields', field);
      }
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if icon_code_point column exists before adding
      final result = await db.rawQuery("PRAGMA table_info(categories)");
      final hasIconColumn = result.any(
        (column) => column['name'] == 'icon_code_point',
      );

      if (!hasIconColumn) {
        // Add icon_code_point column to categories table
        await db.execute(
          'ALTER TABLE categories ADD COLUMN icon_code_point INTEGER NOT NULL DEFAULT 0xe2bc',
        );
      }
    }

    if (oldVersion < 3) {
      // Check if color_value column exists before adding
      final result = await db.rawQuery("PRAGMA table_info(categories)");
      final hasColorColumn = result.any(
        (column) => column['name'] == 'color_value',
      );

      if (!hasColorColumn) {
        // Add color_value column to categories table (default orange color)
        await db.execute(
          'ALTER TABLE categories ADD COLUMN color_value INTEGER NOT NULL DEFAULT 4294945792',
        );
      }
    }

    if (oldVersion < 4) {
      // Check if password_items table exists before creating
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='password_items'",
      );

      if (tables.isEmpty) {
        // Create password_items table
        await db.execute('''
          CREATE TABLE password_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            field_values TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
          )
        ''');
      }
    }

    if (oldVersion < 5) {
      // Check if is_masked column exists before adding
      final result = await db.rawQuery("PRAGMA table_info(fields)");
      final hasMaskedColumn = result.any(
        (column) => column['name'] == 'is_masked',
      );

      if (!hasMaskedColumn) {
        // Add is_masked column to fields table
        await db.execute(
          'ALTER TABLE fields ADD COLUMN is_masked INTEGER NOT NULL DEFAULT 0',
        );

        // Set password fields to be masked by default
        await db.execute(
          'UPDATE fields SET is_masked = 1 WHERE LOWER(name) LIKE "%password%" OR LOWER(name) LIKE "%pass%" OR LOWER(name) LIKE "%pwd%"',
        );
      }
    }

    if (oldVersion < 6) {
      // Check if is_favorite column exists before adding
      final result = await db.rawQuery("PRAGMA table_info(password_items)");
      final hasFavoriteColumn = result.any(
        (column) => column['name'] == 'is_favorite',
      );

      if (!hasFavoriteColumn) {
        // Add is_favorite column to password_items table
        await db.execute(
          'ALTER TABLE password_items ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
  }

  // Category operations
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  Future<int> getCategoryId(String categoryName) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [categoryName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }

    // If category doesn't exist, create it
    return await db.insert('categories', {
      'name': categoryName,
      'icon_code_point': 0xe2e6, // Default folder icon
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateCategory(
    int id,
    String name, {
    int? iconCodePoint,
    int? colorValue,
  }) async {
    final db = await database;
    Map<String, dynamic> updateData = {'name': name};

    if (iconCodePoint != null) {
      updateData['icon_code_point'] = iconCodePoint;
    }

    if (colorValue != null) {
      updateData['color_value'] = colorValue;
    }

    return await db.update(
      'categories',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertCategory(
    String name, {
    int iconCodePoint = 0xe2bc,
    int colorValue = 4294945792,
  }) async {
    final db = await database;
    return await db.insert('categories', {
      'name': name,
      'icon_code_point': iconCodePoint,
      'color_value': colorValue,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    // Delete all fields for this category first
    await db.delete('fields', where: 'category_id = ?', whereArgs: [id]);
    // Then delete the category
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC');
  }

  // Field operations
  Future<List<Map<String, dynamic>>> getFields(int categoryId) async {
    final db = await database;
    return await db.query(
      'fields',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'order_index ASC',
    );
  }

  Future<int> insertField(Map<String, dynamic> field) async {
    final db = await database;
    return await db.insert('fields', field);
  }

  Future<int> updateField(int id, Map<String, dynamic> field) async {
    final db = await database;
    return await db.update('fields', field, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteField(int id) async {
    final db = await database;
    return await db.delete('fields', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateFieldOrder(List<Map<String, dynamic>> fields) async {
    final db = await database;
    final batch = db.batch();

    for (int i = 0; i < fields.length; i++) {
      batch.update(
        'fields',
        {'order_index': i + 1},
        where: 'id = ?',
        whereArgs: [fields[i]['id']],
      );
    }

    await batch.commit();
  }

  // Password Items CRUD operations
  Future<int> insertPasswordItem(Map<String, dynamic> passwordItem) async {
    final db = await database;
    return await db.insert('password_items', passwordItem);
  }

  Future<List<Map<String, dynamic>>> getPasswordItems(int categoryId) async {
    final db = await database;
    return await db.query(
      'password_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'title ASC',
    );
  }

  Future<Map<String, dynamic>?> getPasswordItem(int id) async {
    final db = await database;
    final results = await db.query(
      'password_items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updatePasswordItem(
    int id,
    Map<String, dynamic> passwordItem,
  ) async {
    final db = await database;
    return await db.update(
      'password_items',
      passwordItem,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePasswordItem(int id) async {
    final db = await database;
    return await db.delete('password_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getPasswordItemCount(int categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM password_items WHERE category_id = ?',
      [categoryId],
    );
    return result.first['count'] as int;
  }

  // Toggle favorite status for a password item
  Future<int> updateFavoriteStatus(int id, bool isFavorite) async {
    final db = await database;
    return await db.update(
      'password_items',
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get favorite items for a specific category
  Future<List<Map<String, dynamic>>> getFavoriteItems(int categoryId) async {
    final db = await database;
    return await db.query(
      'password_items',
      where: 'category_id = ? AND is_favorite = 1',
      whereArgs: [categoryId],
      orderBy: 'title ASC',
    );
  }

  // Get all favorite items across all categories
  Future<List<Map<String, dynamic>>> getAllFavoriteItems() async {
    final db = await database;
    return await db.query(
      'password_items',
      where: 'is_favorite = 1',
      orderBy: 'title ASC',
    );
  }
}
