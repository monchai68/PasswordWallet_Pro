class CategoryModel {
  final int? id;
  final String name;
  final int iconCodePoint;
  final String createdAt;

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code_point': iconCodePoint,
      'created_at': createdAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['icon_code_point'],
      createdAt: map['created_at'],
    );
  }
}

class FieldModel {
  final int? id;
  final int categoryId;
  final String name;
  final bool isVisible;
  final bool isRequired;
  final bool isMasked; // Field that should be masked with asterisks
  final int orderIndex;

  FieldModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.isVisible,
    required this.isRequired,
    this.isMasked = false,
    required this.orderIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'is_visible': isVisible ? 1 : 0,
      'is_required': isRequired ? 1 : 0,
      'is_masked': isMasked ? 1 : 0,
      'order_index': orderIndex,
    };
  }

  factory FieldModel.fromMap(Map<String, dynamic> map) {
    return FieldModel(
      id: map['id'],
      categoryId: map['category_id'],
      name: map['name'],
      isVisible: map['is_visible'] == 1,
      isRequired: map['is_required'] == 1,
      isMasked: map['is_masked'] == 1,
      orderIndex: map['order_index'],
    );
  }
}

// For UI use (backward compatibility)
class FieldItem {
  int? id;
  String name;
  bool isVisible;
  bool isRequired;
  bool isMasked; // Field that should be masked with asterisks
  int order;

  FieldItem({
    this.id,
    required this.name,
    required this.isVisible,
    required this.isRequired,
    this.isMasked = false,
    required this.order,
  });

  // Convert from FieldModel
  factory FieldItem.fromModel(FieldModel model) {
    return FieldItem(
      id: model.id,
      name: model.name,
      isVisible: model.isVisible,
      isRequired: model.isRequired,
      isMasked: model.isMasked,
      order: model.orderIndex,
    );
  }

  // Convert to FieldModel
  FieldModel toModel(int categoryId) {
    return FieldModel(
      id: id,
      categoryId: categoryId,
      name: name,
      isVisible: isVisible,
      isRequired: isRequired,
      isMasked: isMasked,
      orderIndex: order,
    );
  }
}

// Model for password items
class PasswordItemModel {
  final int? id;
  final int? categoryId; // Added for database compatibility
  final String categoryName;
  final String itemName;
  final Map<String, String> fieldValues; // Field name -> value
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite; // Added for favorite functionality

  PasswordItemModel({
    this.id,
    this.categoryId,
    required this.categoryName,
    required this.itemName,
    required this.fieldValues,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': itemName, // Use 'title' to match database schema
      'field_values': fieldValues.entries
          .map((e) => '${e.key}|${e.value}')
          .join(';;'),
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory PasswordItemModel.fromMap(Map<String, dynamic> map) {
    Map<String, String> fieldValues = {};
    if (map['field_values'] != null && map['field_values'].isNotEmpty) {
      final fields = map['field_values'].split(';;');
      for (var field in fields) {
        final parts = field.split('|');
        if (parts.length == 2) {
          fieldValues[parts[0]] = parts[1];
        }
      }
    }

    return PasswordItemModel(
      id: map['id'],
      categoryId: map['category_id'],
      categoryName: '', // Will be populated separately if needed
      itemName: map['title'] ?? '',
      fieldValues: fieldValues,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      isFavorite: (map['is_favorite'] ?? 0) == 1,
    );
  }
}

class PasswordItem {
  final int? id;
  final String categoryName;
  final String name;
  final Map<String, String> fieldData;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PasswordItem({
    this.id,
    required this.categoryName,
    required this.name,
    required this.fieldData,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_name': categoryName,
      'name': name,
      'field_data': fieldData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory PasswordItem.fromMap(Map<String, dynamic> map) {
    return PasswordItem(
      id: map['id'],
      categoryName: map['category_name'],
      name: map['name'],
      fieldData: Map<String, String>.from(map['field_data'] ?? {}),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}
