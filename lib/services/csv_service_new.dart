import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'category_service.dart';
import '../models/field_models.dart';

class CSVService {
  final CategoryService _categoryService = CategoryService();

  /// Import CSV file and parse data into database
  Future<Map<String, dynamic>> importCSV() async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return {'success': false, 'message': 'No file selected'};
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Extract category name from filename (remove .csv extension)
      final categoryName = fileName.replaceAll('.csv', '');

      // Read and parse CSV
      final csvContent = await file.readAsString();
      List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvContent,
      );

      if (csvData.isEmpty) {
        return {'success': false, 'message': 'CSV file is empty'};
      }

      // First row contains field names
      List<String> fieldNames = csvData[0].map((e) => e.toString()).toList();

      if (fieldNames.isEmpty || fieldNames[0].isEmpty) {
        return {
          'success': false,
          'message': 'Invalid CSV format: First column should be item name',
        };
      }

      // Check if category exists, if not create it
      final categories = await _categoryService.getAllCategories();
      bool categoryExists = categories.contains(categoryName);

      if (!categoryExists) {
        // Create new category
        bool created = await _categoryService.createCategory(categoryName);
        if (!created) {
          return {
            'success': false,
            'message': 'Failed to create category: $categoryName',
          };
        }

        // Create fields for the new category
        int categoryId = await _categoryService.getCategoryId(categoryName);
        for (int i = 1; i < fieldNames.length; i++) {
          FieldItem field = FieldItem(
            name: fieldNames[i],
            isVisible: true,
            isRequired: false,
            isMasked: _shouldMaskField(fieldNames[i]),
            order: i,
          );
          await _categoryService.saveField(field, categoryName);
        }
      }

      // Import data rows
      int importedCount = 0;
      int updatedCount = 0;

      for (int i = 1; i < csvData.length; i++) {
        List<dynamic> row = csvData[i];
        if (row.isEmpty || row[0].toString().trim().isEmpty) {
          continue; // Skip empty rows
        }

        String itemName = row[0].toString().trim();

        // Create field data map
        Map<String, String> fieldData = {};
        for (int j = 1; j < fieldNames.length && j < row.length; j++) {
          String fieldName = fieldNames[j];
          String fieldValue = row[j].toString().trim();
          if (fieldValue.isNotEmpty) {
            fieldData[fieldName] = fieldValue;
          }
        }

        // Check if item already exists
        final existingItems = await _categoryService.getPasswordItems(
          categoryName,
        );
        PasswordItemModel? existingItem;

        for (var item in existingItems) {
          if (item.itemName == itemName) {
            existingItem = item;
            break;
          }
        }

        if (existingItem != null) {
          // Update existing item
          final updatedItem = PasswordItemModel(
            id: existingItem.id,
            categoryId: existingItem.categoryId,
            categoryName: categoryName,
            itemName: itemName,
            fieldValues: fieldData,
            createdAt: existingItem.createdAt,
            updatedAt: DateTime.now(),
            isFavorite: existingItem.isFavorite,
          );
          await _categoryService.savePasswordItem(updatedItem);
          updatedCount++;
        } else {
          // Create new item
          final newItem = PasswordItemModel(
            categoryName: categoryName,
            itemName: itemName,
            fieldValues: fieldData,
            createdAt: DateTime.now(),
            isFavorite: false,
          );
          await _categoryService.savePasswordItem(newItem);
          importedCount++;
        }
      }

      return {
        'success': true,
        'message': 'Import completed successfully',
        'categoryName': categoryName,
        'importedCount': importedCount,
        'updatedCount': updatedCount,
      };
    } catch (e) {
      print('Error importing CSV: $e');
      return {
        'success': false,
        'message': 'Error importing CSV: ${e.toString()}',
      };
    }
  }

  /// Determine if field should be masked based on field name
  bool _shouldMaskField(String fieldName) {
    final lowercaseName = fieldName.toLowerCase();
    return lowercaseName.contains('password') ||
        lowercaseName.contains('pass') ||
        lowercaseName.contains('pwd');
  }

  /// Export category data to CSV (placeholder for future implementation)
  Future<Map<String, dynamic>> exportCSV(String categoryName) async {
    try {
      // Get all items in category
      final items = await _categoryService.getPasswordItems(categoryName);

      if (items.isEmpty) {
        return {
          'success': false,
          'message': 'No items to export in this category',
        };
      }

      // Get category fields
      final fields = await _categoryService.loadFields(categoryName);

      // Create CSV data
      List<List<String>> csvData = [];

      // Header row - field names
      List<String> headers = ['Name'];
      for (var field in fields) {
        headers.add(field.name);
      }
      csvData.add(headers);

      // Data rows
      for (var item in items) {
        List<String> row = [item.itemName];
        for (var field in fields) {
          String value = item.fieldValues[field.name] ?? '';
          row.add(value);
        }
        csvData.add(row);
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);

      return {
        'success': true,
        'csvData': csvString,
        'fileName': '$categoryName.csv',
        'itemCount': items.length,
      };
    } catch (e) {
      print('Error exporting CSV: $e');
      return {
        'success': false,
        'message': 'Error exporting CSV: ${e.toString()}',
      };
    }
  }
}
