# Field Masking Feature Implementation

## 🎯 ฟีเจอร์ใหม่: การมาสก์ Field ด้วย Checkbox

### ความต้องการเดิม:
ในหน้า Category Editor ต้องการให้ field ที่มีการ check (checkbox ที่เห็นในรูป) จะถูกมาสก์ด้วย asterisk (*) เมื่อแสดงข้อมูล และมี icon รูปตาให้กดเพื่อ toggle การแสดง/ซ่อนข้อมูล

### ✅ การแก้ไขที่ทำไปแล้ว:

#### 1. **อัปเดต Database Schema**
- เพิ่มคอลัมน์ `is_masked` ในตาราง `fields`
- อัปเดต database version จาก 4 เป็น 5
- เพิ่ม migration logic สำหรับ existing fields
- ตั้งค่า Password fields ให้ masked by default

```sql
-- เพิ่มคอลัมน์ใหม่
ALTER TABLE fields ADD COLUMN is_masked INTEGER NOT NULL DEFAULT 0;

-- ตั้งค่า password fields ให้เป็น masked
UPDATE fields SET is_masked = 1 WHERE LOWER(name) LIKE "%password%" 
  OR LOWER(name) LIKE "%pass%" OR LOWER(name) LIKE "%pwd%";
```

#### 2. **อัปเดต Field Models**
- เพิ่ม property `isMasked` ใน `FieldModel` และ `FieldItem`
- อัปเดต `toMap()`, `fromMap()`, `fromModel()`, `toModel()` methods
- ตั้งค่า default `isMasked = false` สำหรับ compatibility

```dart
class FieldModel {
  final bool isMasked; // Field that should be masked with asterisks
  
  FieldModel({
    this.isMasked = false,
    // ... other properties
  });
}
```

#### 3. **แก้ไข Category Field Editor Screen**
- เพิ่ม checkbox ที่สองสำหรับการมาสก์ (ข้าง checkbox visibility)
- อัปเดตหัวตาราง เพิ่ม icon รูปตาสำหรับ masking column
- เพิ่มการตรวจจับ auto-masking เมื่อสร้าง field ใหม่ที่มีคำว่า "password"

```dart
// Header อัปเดต
Icon(Icons.visibility, color: Colors.black54, size: 20),     // สำหรับ visibility
Icon(Icons.remove_red_eye, color: Colors.black54, size: 20), // สำหรับ masking

// Mask checkbox
GestureDetector(
  onTap: () {
    setState(() {
      field.isMasked = !field.isMasked;
    });
    _saveFieldChange(field);
  },
  child: Container(...), // checkbox สำหรับ masking
),
```

#### 4. **แก้ไข Item Detail Screen**
- อัปเดต `_buildFieldRow()` เพื่อใช้ field configuration แทนการตรวจชื่อ field
- เปลี่ยนจาก dots (•) เป็น asterisks (*) สำหรับการมาสก์
- จำนวน asterisks ตามความยาวจริงของข้อมูล
- อัปเดต `_initializeVisibilityStates()` ให้ใช้ `isMasked` property

```dart
Widget _buildFieldRow(String fieldName, String value) {
  final fieldConfig = categoryFields.firstWhere(
    (field) => field.name == fieldName,
    orElse: () => FieldItem(
      isMasked: fieldName.toLowerCase().contains('password'),
      // ... fallback config
    ),
  );
  
  final isMasked = fieldConfig.isMasked;
  
  // แสดงข้อมูล
  Text(
    isEmpty ? '(No data)' 
    : (isMasked && !isVisible ? '*' * value.length : value),
    // ...
  ),
}
```

#### 5. **แก้ไข Add New Item Screen**
- อัปเดต `_buildFieldInput()` เพื่อใช้ `field.isMasked` แทนการตรวจชื่อ field
- ใช้ obscureText สำหรับ fields ที่ถูกตั้งค่าให้มาสก์

```dart
Widget _buildFieldInput(FieldItem field) {
  bool shouldObscure = field.isMasked; // ใช้ field configuration
  
  TextField(
    obscureText: shouldObscure ? _obscurePassword : false,
    decoration: InputDecoration(
      suffixIcon: shouldObscure ? IconButton(...) : null,
    ),
  );
}
```

### 🔄 การทำงานของระบบ:

#### ในหน้า Category Editor:
1. **Checkbox แรก (visibility icon)**: ควบคุมว่า field จะแสดงใน form หรือไม่
2. **Checkbox ที่สอง (eye icon)**: ควบคุมว่า field จะถูกมาสก์หรือไม่

#### ในหน้า Item Detail:
1. **Field ที่ isMasked = true**: แสดงเป็น asterisks (*) ตามความยาวจริง
2. **มี eye icon**: กดเพื่อ toggle แสดง/ซ่อนข้อมูล
3. **Field ที่ isMasked = false**: แสดงข้อมูลธรรมดา ไม่มี eye icon

#### ในหน้า Add/Edit Item:
1. **Field ที่ isMasked = true**: ใช้ obscureText ในการป้อนข้อมูล
2. **มี eye icon**: กดเพื่อ toggle แสดง/ซ่อนข้อมูลขณะพิมพ์

### 📁 ไฟล์ที่แก้ไข:

1. **`lib/models/field_models.dart`**
   - เพิ่ม `isMasked` property
   - อัปเดต serialization methods

2. **`lib/database/database_helper.dart`**
   - เพิ่ม `is_masked` column
   - อัปเดต database version เป็น 5
   - เพิ่ม migration logic

3. **`lib/screens/category_field_editor_screen.dart`**
   - เพิ่ม masking checkbox
   - อัปเดต header icons
   - เพิ่ม auto-masking logic

4. **`lib/screens/item_detail_screen.dart`**
   - อัปเดต field display logic
   - เปลี่ยนจาก dots เป็น asterisks
   - ใช้ field configuration

5. **`lib/screens/add_new_item_screen.dart`**
   - อัปเดต field input logic
   - ใช้ `field.isMasked` property

### 🚀 ผลลัพธ์:

- **ใน Category Editor**: สามารถกำหนดได้ว่า field ไหนควรถูกมาสก์
- **Password fields**: ถูกตั้งให้มาสก์ by default
- **Custom fields**: สามารถเลือกได้ว่าจะมาสก์หรือไม่
- **ข้อมูลเก่า**: ยังคงทำงานได้ด้วย fallback logic
- **Consistent UX**: การแสดงผลเหมือนกันทุกหน้า

### 🔧 การใช้งาน:

1. ไปหน้า **Category Editor**
2. เลือก category ที่ต้องการแก้ไข
3. ดู field list ที่มี **2 checkboxes**:
   - **Checkbox แรก**: แสดง field หรือไม่
   - **Checkbox ที่สอง (eye icon)**: มาสก์ field หรือไม่
4. **Check** checkbox ที่สองสำหรับ fields ที่ต้องการมาสก์
5. ไปดูผลลัพธ์ในหน้า **Item Detail** และ **Add/Edit Item**

Fields ที่ถูกมาสก์จะแสดงเป็น `*****` และมี eye icon ให้กดเพื่อดูข้อมูลจริง! 🎉
