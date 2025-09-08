import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/models/field_models.dart';
import 'lib/services/category_service.dart';

void main() async {
  print('Testing Database Implementation (Console Version)...\n');

  try {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Initialize the service
    CategoryService categoryService = CategoryService();

    // Test 1: Load existing fields for "Personal" category
    print('Test 1: Loading existing fields for "Personal" category');
    List<FieldItem> personalFields = await categoryService.loadFields(
      'Personal',
    );
    print('Found ${personalFields.length} fields:');
    for (FieldItem field in personalFields) {
      print(
        '  - ${field.name} (visible: ${field.isVisible}, required: ${field.isRequired})',
      );
    }
    print('');

    // Test 2: Add a new field
    print('Test 2: Adding a new field "Test Field"');
    FieldItem newField = FieldItem(
      name: 'Test Field',
      isVisible: true,
      isRequired: false,
      order: personalFields.length + 1,
    );

    bool saveResult = await categoryService.saveField(newField, 'Personal');
    print('Save result: $saveResult');
    print('New field ID: ${newField.id}');
    print('');

    // Test 3: Load fields again to verify the new field was saved
    print('Test 3: Loading fields again to verify save');
    List<FieldItem> updatedFields = await categoryService.loadFields(
      'Personal',
    );
    print('Now found ${updatedFields.length} fields:');
    for (FieldItem field in updatedFields) {
      print('  - ${field.name} (ID: ${field.id}, visible: ${field.isVisible})');
    }
    print('');

    // Test 4: Update the test field
    if (newField.id != null) {
      print('Test 4: Updating the test field');
      newField.isRequired = true;
      newField.isVisible = false;
      bool updateResult = await categoryService.saveField(newField, 'Personal');
      print('Update result: $updateResult');
      print('');
    }

    // Test 5: Load fields to verify update
    print('Test 5: Loading fields to verify update');
    List<FieldItem> finalFields = await categoryService.loadFields('Personal');
    FieldItem? testField;
    for (FieldItem field in finalFields) {
      if (field.name == 'Test Field') {
        testField = field;
        break;
      }
    }

    if (testField != null) {
      print('Test field found:');
      print('  - Name: ${testField.name}');
      print('  - Required: ${testField.isRequired}');
      print('  - Visible: ${testField.isVisible}');
    } else {
      print('Test field not found!');
    }
    print('');

    // Test 6: Delete the test field
    if (testField != null) {
      print('Test 6: Deleting the test field');
      bool deleteResult = await categoryService.deleteField(testField);
      print('Delete result: $deleteResult');

      // Verify deletion
      List<FieldItem> afterDelete = await categoryService.loadFields(
        'Personal',
      );
      print('Fields after deletion: ${afterDelete.length}');
      bool stillExists = afterDelete.any((f) => f.name == 'Test Field');
      print('Test field still exists: $stillExists');
    }

    print('\n✅ Database test completed successfully!');
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}
