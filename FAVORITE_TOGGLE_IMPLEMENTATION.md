# Favorite Toggle Functionality Implementation

## ❤️ การ Implement Favorite Toggle ในรายการ Password Items

### ปัญหาเดิม:
- ต้องการให้ heart icon ที่เป็น outline สามารถ toggle ได้
- เมื่อ tap ที่ icon จะเปลี่ยนจาก outline เป็นสีแดงเต็ม
- ต้องบันทึกสถานะ favorite ใน database

### ✅ การแก้ไขที่ทำ:

#### 1. อัปเดต Model สำหรับ isFavorite:
```dart
// lib/models/field_models.dart
class PasswordItemModel {
  final bool isFavorite; // เพิ่ม field ใหม่
  
  PasswordItemModel({
    // ... fields อื่นๆ
    this.isFavorite = false, // default เป็น false
  });
  
  // อัปเดต toMap()
  Map<String, dynamic> toMap() {
    return {
      // ... fields อื่นๆ
      'is_favorite': isFavorite ? 1 : 0,
    };
  }
  
  // อัปเดต fromMap()
  factory PasswordItemModel.fromMap(Map<String, dynamic> map) {
    return PasswordItemModel(
      // ... fields อื่นๆ
      isFavorite: (map['is_favorite'] ?? 0) == 1,
    );
  }
}
```

#### 2. อัปเดต Database Schema:
```dart
// lib/database/database_helper.dart

// เปลี่ยน database version เป็น 6
version: 6, // เพิ่มจาก 5 → 6

// อัปเดต table creation
CREATE TABLE password_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  field_values TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0, // เพิ่ม column ใหม่
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
)

// เพิ่ม migration สำหรับ version 6
if (oldVersion < 6) {
  await db.execute(
    'ALTER TABLE password_items ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
  );
}
```

#### 3. เพิ่ม Database Methods:
```dart
// lib/database/database_helper.dart

// Method สำหรับ toggle favorite
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
```

#### 4. อัปเดต Service Layer:
```dart
// lib/services/category_service.dart

// Method สำหรับ toggle favorite
Future<bool> toggleFavorite(int itemId, bool isFavorite) async {
  try {
    await _db.updateFavoriteStatus(itemId, isFavorite);
    return true;
  } catch (e) {
    print('Error toggling favorite: $e');
    return false;
  }
}
```

#### 5. อัปเดต UI Components:
```dart
// lib/screens/category_password_list_screen.dart

trailing: GestureDetector(
  onTap: () async {
    // Toggle favorite status
    final newFavoriteStatus = !passwordItem.isFavorite;
    final success = await _categoryService.toggleFavorite(
      passwordItem.id!,
      newFavoriteStatus,
    );
    
    if (success) {
      // Refresh list เพื่อแสดงสถานะใหม่
      _loadPasswordItems();
    }
  },
  child: Icon(
    passwordItem.isFavorite ? Icons.favorite : Icons.favorite_border,
    color: passwordItem.isFavorite 
        ? Colors.red 
        : Colors.grey.withOpacity(0.68),
    size: 24,
  ),
),
```

#### 6. อัปเดต AddNewItemScreen:
```dart
// lib/screens/add_new_item_screen.dart

PasswordItemModel passwordItem = PasswordItemModel(
  // ... fields อื่นๆ
  isFavorite: widget.editingItem?.isFavorite ?? false, // preserve favorite status
);
```

### 🎯 **การทำงานของ Favorite Toggle:**

#### ✨ **UI Behavior:**
1. **Icon แบบ Outline**: `Icons.favorite_border` สีเทา opacity 68%
2. **Icon แบบ Filled**: `Icons.favorite` สีแดง
3. **Tap Gesture**: แตะที่ icon เพื่อ toggle
4. **Real-time Update**: รายการ refresh ทันทีหลัง toggle

#### 📱 **ตัวอย่างการใช้งาน:**

```
ก่อน Toggle (Outline):
┌─────────────────────────────────────┐
│ 4Shared                         ♡   │ ← เทาอ่อน outline
│ All pharmacy                    ♡   │
│ Drop Box                        ♡   │
│ Fastwork                        ♡   │
│ Figma                           ♡   │
└─────────────────────────────────────┘

หลัง Toggle Figma (Filled):
┌─────────────────────────────────────┐
│ 4Shared                         ♡   │ ← เทาอ่อน outline
│ All pharmacy                    ♡   │
│ Drop Box                        ♡   │
│ Fastwork                        ♡   │
│ Figma                           ❤️   │ ← สีแดงเต็ม
└─────────────────────────────────────┘
```

### 🔄 **Database Schema Updates:**

#### ✅ **Version History:**
- **Version 5**: เพิ่ม `is_masked` column ใน fields table
- **Version 6**: เพิ่ม `is_favorite` column ใน password_items table

#### 📊 **Table Structure (password_items):**
```sql
CREATE TABLE password_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  field_values TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_favorite INTEGER NOT NULL DEFAULT 0, -- ✨ ใหม่
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
)
```

### 🚀 **ประโยชน์ที่ได้:**

#### 👁️ **UX Improvements:**
- **Visual Feedback**: แสดงสถานะ favorite ชัดเจน
- **Interactive**: สามารถ toggle ได้ง่าย
- **Consistent**: ใช้ Material Design icons มาตรฐาน

#### 📱 **Functionality:**
- **Persistent**: บันทึกสถานะใน database
- **Real-time**: อัปเดตทันทีหลัง toggle
- **Reliable**: มี error handling

#### 🎯 **Future Ready:**
- **Filter by Favorites**: สามารถเพิ่มฟีเจอร์กรองรายการ favorite ได้
- **Favorites Screen**: สามารถสร้างหน้า favorites แยกได้
- **Sort by Favorites**: สามารถเรียงลำดับตาม favorite ได้

### 📁 **ไฟล์ที่แก้ไข:**
1. **`lib/models/field_models.dart`**
   - เพิ่ม `isFavorite` field ใน PasswordItemModel
   - อัปเดต `toMap()` และ `fromMap()` methods

2. **`lib/database/database_helper.dart`**
   - อัปเดต database version เป็น 6
   - เพิ่ม `is_favorite` column ใน table creation
   - เพิ่ม migration สำหรับ version 6
   - เพิ่ม `updateFavoriteStatus()` method

3. **`lib/services/category_service.dart`**
   - เพิ่ม `toggleFavorite()` method

4. **`lib/screens/category_password_list_screen.dart`**
   - อัปเดต `trailing` widget เป็น `GestureDetector`
   - เพิ่ม toggle functionality
   - Dynamic icon และ color

5. **`lib/screens/add_new_item_screen.dart`**
   - อัปเดต PasswordItemModel creation เพื่อรองรับ `isFavorite`

### ✨ **ผลลัพธ์สุดท้าย:**

ตอนนี้ทุก item ในรายการจะมี:
- **Heart Icon**: แสดงสถานะ favorite
- **Interactive Toggle**: แตะเพื่อ toggle favorite
- **Visual Feedback**: เปลี่ยนสีและ icon แบบ real-time
- **Persistent Storage**: บันทึกสถานะใน database
- **Cross-Screen Consistency**: สถานะ favorite จะคงอยู่ทุกหน้า

**การทำงาน:**
- 🤍 **Outline Heart**: ยังไม่ favorite (เทา 68%)
- ❤️ **Filled Heart**: เป็น favorite แล้ว (สีแดง)
- 👆 **Tap**: toggle ระหว่าง favorite/unfavorite
- 🔄 **Real-time**: อัปเดตทันทีไม่ต้องรอ
