import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import '../models/field_models.dart';
import 'category_service.dart';

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
      print('CSV Import: Category name = $categoryName');

      // Read and parse CSV
      final csvContent = await file.readAsString();
      print('CSV Import: File content length = ${csvContent.length}');

      // Check if file contains proper line breaks
      if (!csvContent.contains('\n') && !csvContent.contains('\r')) {
        return {
          'success': false,
          'message':
              'Invalid CSV format: File must contain multiple rows separated by line breaks',
        };
      }

      List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvContent,
      );
      print('CSV Import: Parsed ${csvData.length} rows');

      if (csvData.isEmpty) {
        return {'success': false, 'message': 'CSV file is empty'};
      }

      if (csvData.length < 2) {
        return {
          'success': false,
          'message': 'CSV file must have at least 2 rows (header + data)',
        };
      }

      // First row contains field names
      List<String> fieldNames = csvData[0].map((e) => e.toString()).toList();
      print('CSV Import: Field names = $fieldNames');

      if (fieldNames.isEmpty || fieldNames[0].isEmpty) {
        return {
          'success': false,
          'message': 'Invalid CSV format: First column should be item name',
        };
      }

      // Check if category exists, if not create it
      final categories = await _categoryService.getAllCategories();
      print('CSV Import: Existing categories = $categories');
      bool categoryExists = categories.contains(categoryName);
      print('CSV Import: Category exists = $categoryExists');

      if (!categoryExists) {
        // Create new category
        print('CSV Import: Creating new category...');
        bool created = await _categoryService.createCategory(categoryName);
        print('CSV Import: Category created = $created');
        if (!created) {
          return {
            'success': false,
            'message': 'Failed to create category: $categoryName',
          };
        }

        // Create fields for the new category
        int categoryId = await _categoryService.getCategoryId(categoryName);
        print('CSV Import: Category ID = $categoryId');
        for (int i = 1; i < fieldNames.length; i++) {
          FieldItem field = FieldItem(
            name: fieldNames[i],
            isVisible: true,
            isRequired: false,
            isMasked: _shouldMaskField(fieldNames[i]),
            order: i,
          );
          bool fieldSaved = await _categoryService.saveField(
            field,
            categoryName,
          );
          print('CSV Import: Field "${fieldNames[i]}" saved = $fieldSaved');
        }
      }

      // Import data rows
      int importedCount = 0;
      int updatedCount = 0;
      print(
        'CSV Import: Starting to import ${csvData.length - 1} data rows...',
      );

      for (int i = 1; i < csvData.length; i++) {
        List<dynamic> row = csvData[i];
        print('CSV Import: Processing row $i: $row');
        if (row.isEmpty || row[0].toString().trim().isEmpty) {
          print('CSV Import: Skipping empty row $i');
          continue; // Skip empty rows
        }

        String itemName = row[0].toString().trim();
        print('CSV Import: Item name = "$itemName"');

        // Create field data map
        Map<String, String> fieldData = {};
        for (int j = 1; j < fieldNames.length && j < row.length; j++) {
          String fieldName = fieldNames[j];
          String fieldValue = row[j].toString().trim();
          if (fieldValue.isNotEmpty) {
            fieldData[fieldName] = fieldValue;
          }
        }
        print('CSV Import: Field data = $fieldData');

        // Check if item already exists
        final existingItems = await _categoryService.getPasswordItems(
          categoryName,
        );
        print(
          'CSV Import: Found ${existingItems.length} existing items in category',
        );
        PasswordItemModel? existingItem;

        for (var item in existingItems) {
          if (item.itemName == itemName) {
            existingItem = item;
            print('CSV Import: Found existing item with same name');
            break;
          }
        }

        if (existingItem != null) {
          // Update existing item
          print('CSV Import: Updating existing item...');
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
          bool saved = await _categoryService.savePasswordItem(updatedItem);
          print('CSV Import: Updated item saved = $saved');
          if (saved) updatedCount++;
        } else {
          // Create new item
          print('CSV Import: Creating new item...');
          final newItem = PasswordItemModel(
            categoryName: categoryName,
            itemName: itemName,
            fieldValues: fieldData,
            createdAt: DateTime.now(),
            isFavorite: false,
          );
          bool saved = await _categoryService.savePasswordItem(newItem);
          print('CSV Import: New item saved = $saved');
          if (saved) importedCount++;
        }
      }

      print(
        'CSV Import: Completed! Imported: $importedCount, Updated: $updatedCount',
      );
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

  /// Export all categories data to a single CSV file
  Future<Map<String, dynamic>> exportAllCategories() async {
    try {
      print('CSV Export: Starting export for all categories');

      // Get all categories
      final categories = await _categoryService.getAllCategories();
      print('CSV Export: Found ${categories.length} categories');

      if (categories.isEmpty) {
        return {'success': false, 'message': 'No categories found to export'};
      }

      int totalItemsExported = 0;
      List<String> exportedCategories = [];
      List<String> emptyCategories = [];

      // Create combined CSV data
      List<List<String>> allCsvData = [];

      // Add header row
      allCsvData.add(['Category', 'Item Name', 'Field Name', 'Field Value']);

      // Export each category
      for (String categoryName in categories) {
        try {
          // Get all items in category
          final items = await _categoryService.getPasswordItems(categoryName);
          print(
            'CSV Export: Category "$categoryName" has ${items.length} items',
          );

          if (items.isEmpty) {
            emptyCategories.add(categoryName);
            continue;
          }

          // Get category fields
          final fields = await _categoryService.loadFields(categoryName);
          print(
            'CSV Export: Category "$categoryName" has ${fields.length} fields',
          );

          // Add data rows for this category
          for (var item in items) {
            for (var field in fields) {
              String value = item.fieldValues[field.name] ?? '';
              allCsvData.add([categoryName, item.itemName, field.name, value]);
            }
          }

          exportedCategories.add(categoryName);
          totalItemsExported += items.length;
        } catch (e) {
          print('CSV Export: Error exporting category "$categoryName": $e');
        }
      }

      if (allCsvData.length <= 1) {
        // Only header row
        return {'success': false, 'message': 'No data to export'};
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(allCsvData);

      print(
        'CSV Export: Generated combined CSV with ${allCsvData.length} rows',
      );

      // Save file using file picker (UTF-8 with BOM for better compatibility)
      final bom = <int>[0xEF, 0xBB, 0xBF];
      final utf8Bytes = utf8.encode(csvString);
      final csvBytes = Uint8List.fromList(bom + utf8Bytes);
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save All Categories Export',
        fileName: 'all_categories_export.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: csvBytes,
      );

      print('CSV Export: Export completed successfully');

      String message =
          'Successfully exported $totalItemsExported items from ${exportedCategories.length} categories';
      if (emptyCategories.isNotEmpty) {
        message +=
            '\n\nEmpty categories skipped: ${emptyCategories.join(', ')}';
      }

      return {
        'success': true,
        'message': message,
        'fileName': 'all_categories_export.csv',
        'totalItemsExported': totalItemsExported,
        'exportedCategories': exportedCategories,
        'emptyCategories': emptyCategories,
      };
    } catch (e) {
      print('Error exporting CSV: $e');
      return {
        'success': false,
        'message': 'Error exporting CSV: ${e.toString()}',
      };
    }
  }

  /// Export all categories as separate CSV files inside a single ZIP
  Future<Map<String, dynamic>> exportAllCategoriesSplit() async {
    try {
      print('CSV Export (Split): Starting export for all categories');

      // Get all categories
      final categories = await _categoryService.getAllCategories();
      print('CSV Export (Split): Found ${categories.length} categories');

      if (categories.isEmpty) {
        return {'success': false, 'message': 'No categories found to export'};
      }

      int totalItemsExported = 0;
      int fileCount = 0;
      List<String> exportedCategories = [];
      List<String> emptyCategories = [];

      final archive = Archive();

      for (final categoryName in categories) {
        try {
          final items = await _categoryService.getPasswordItems(categoryName);
          print(
            'CSV Export (Split): Category "$categoryName" has ${items.length} items',
          );

          if (items.isEmpty) {
            emptyCategories.add(categoryName);
            continue;
          }

          final fields = await _categoryService.loadFields(categoryName);
          print(
            'CSV Export (Split): Category "$categoryName" has ${fields.length} fields',
          );

          // Build per-category CSV: headers = [Name] + field names
          final List<List<String>> csvData = [];
          final headers = <String>['Name', ...fields.map((f) => f.name)];
          csvData.add(headers);

          for (var item in items) {
            final row = <String>[item.itemName];
            for (var field in fields) {
              row.add(item.fieldValues[field.name] ?? '');
            }
            csvData.add(row);
          }

          final csvString = const ListToCsvConverter().convert(csvData);
          // UTF-8 with BOM for each CSV inside the ZIP
          final bom = <int>[0xEF, 0xBB, 0xBF];
          final utf8Bytes = utf8.encode(csvString);
          final bytes = Uint8List.fromList(bom + utf8Bytes);

          // Sanitize file name
          final safeName = _sanitizeFileName('$categoryName.csv');
          archive.addFile(ArchiveFile(safeName, bytes.length, bytes));

          exportedCategories.add(categoryName);
          totalItemsExported += items.length;
          fileCount += 1;
        } catch (e) {
          print('CSV Export (Split): Error on "$categoryName": $e');
        }
      }

      if (archive.files.isEmpty) {
        return {'success': false, 'message': 'No data to export'};
      }

      // Encode ZIP in memory
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) {
        return {'success': false, 'message': 'Failed to create ZIP archive'};
      }

      // Save ZIP via save dialog (SAF-friendly)
      final String defaultName = 'categories_export.zip';
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Categories as ZIP',
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );

      String message =
          'Successfully exported $totalItemsExported items into $fileCount CSV files';
      if (emptyCategories.isNotEmpty) {
        message +=
            '\n\nEmpty categories skipped: ${emptyCategories.join(', ')}';
      }

      return {
        'success': true,
        'message': message,
        'fileName': defaultName,
        'fileType': 'zip',
        'fileCount': fileCount,
        'totalItemsExported': totalItemsExported,
        'exportedCategories': exportedCategories,
        'emptyCategories': emptyCategories,
      };
    } catch (e) {
      print('Error exporting split ZIP: $e');
      return {
        'success': false,
        'message': 'Error exporting ZIP: ${e.toString()}',
      };
    }
  }

  String _sanitizeFileName(String input) {
    // Remove/replace characters illegal in file names across OSes
    final sanitized = input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? 'file.csv' : sanitized;
  }

  /// Export category data to CSV file
  Future<Map<String, dynamic>> exportCSV(String categoryName) async {
    try {
      print('CSV Export: Starting export for category "$categoryName"');

      // Get all items in category
      final items = await _categoryService.getPasswordItems(categoryName);
      print('CSV Export: Found ${items.length} items');

      if (items.isEmpty) {
        return {
          'success': false,
          'message': 'No items to export in this category',
        };
      }

      // Get category fields
      final fields = await _categoryService.loadFields(categoryName);
      print('CSV Export: Found ${fields.length} fields');

      // Create CSV data
      List<List<String>> csvData = [];

      // Header row - field names (first column is "Name")
      List<String> headers = ['Name'];
      for (var field in fields) {
        headers.add(field.name);
      }
      csvData.add(headers);
      print('CSV Export: Headers = $headers');

      // Data rows
      for (var item in items) {
        List<String> row = [item.itemName];
        for (var field in fields) {
          String value = item.fieldValues[field.name] ?? '';
          row.add(value);
        }
        csvData.add(row);
        print('CSV Export: Added row for item "${item.itemName}"');
      }

      // Convert to CSV string
      String csvString = const ListToCsvConverter().convert(csvData);
      print(
        'CSV Export: Generated CSV content (${csvString.length} characters)',
      );

      // Let user choose save location
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      // Create the file
      final fileName = '$categoryName.csv';
      final filePath = '$selectedDirectory/$fileName';
      final file = File(filePath);

      print('CSV Export: Saving to $filePath');
      await file.writeAsString(csvString);

      print('CSV Export: Export completed successfully');
      return {
        'success': true,
        'message': 'Export completed successfully',
        'fileName': fileName,
        'filePath': filePath,
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
