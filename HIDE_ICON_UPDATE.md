# Icon Update - Hide Icon Implementation

## 🎯 การอัปเดต Icon ในหัวตาราง Category Field Editor

### ปัญหาเดิม:
- ใช้ `Icons.remove_red_eye` (รูปตาปกติ) สำหรับหัวคอลัมน์ masking
- ผู้ใช้ต้องการเปลี่ยนเป็น icon hide (ตาถูกขีดฆ่า) เพื่อให้เข้าใจง่ายขึ้น

### ✅ การแก้ไขที่ทำ:

#### เปลี่ยน Icon ในหัวตาราง:
```dart
// เดิม
Icon(Icons.remove_red_eye, color: Colors.black54, size: 20),

// ใหม่  
Icon(Icons.visibility_off, color: Colors.black54, size: 20),
```

### 🎨 **ความหมายของ Icon ใหม่:**

#### `Icons.visibility_off` (👁️⃠):
- **รูปลักษณ์**: ตาที่มีเส้นทแยงขีดผ่าน
- **ความหมาย**: "ซ่อน" หรือ "ไม่แสดง"
- **การใช้งาน**: checkbox สำหรับเลือกว่าจะมาสก์ field หรือไม่

### 📱 **UI ที่อัปเดต:**

```
Category Editor Header:
┌────────────────┬─────────────────┬────────┐
│ Field Name     │ 👁️⃠ Hide       │ Delete │
├────────────────┼─────────────────┼────────┤
│ Name           │ ☐               │ ❌     │
│ Login          │ ☐               │ ❌     │
│ Password       │ ☑️              │ ❌     │
│ Email          │ ☐               │ ❌     │
│ Note           │ ☐               │ ❌     │
└────────────────┴─────────────────┴────────┘
```

### 🔄 **การทำงาน:**

1. **Icon หัวตาราง**: `visibility_off` แสดงว่าคอลัมน์นี้ใช้สำหรับเลือก "ซ่อน" ข้อมูล
2. **Checkbox ✅**: เมื่อ check = field จะถูกมาสก์ด้วย `*****`
3. **Checkbox ☐**: เมื่อไม่ check = field แสดงข้อมูลปกติ

### 🎯 **ความชัดเจนขึ้น:**

- **เดิม**: `remove_red_eye` อาจทำให้สับสนว่าใช้ทำอะไร
- **ใหม่**: `visibility_off` ชัดเจนว่าเป็นการ "ซ่อน" ข้อมูล
- **เข้าใจง่าย**: ผู้ใช้เข้าใจทันทีว่า checkbox นี้สำหรับซ่อนข้อมูล

### 📁 **ไฟล์ที่แก้ไข:**
- `lib/screens/category_field_editor_screen.dart`
  - เปลี่ยน header icon จาก `Icons.remove_red_eye` เป็น `Icons.visibility_off`

### ✨ **ผลลัพธ์:**

ตอนนี้หัวตารางจะแสดง **icon ตาถูกขีดฆ่า** (`visibility_off`) เพื่อให้เข้าใจได้ชัดเจนว่าคอลัมน์นี้ใช้สำหรับเลือก fields ที่จะถูกซ่อน/มาสก์! 🎉

### 🔧 **การใช้งาน:**
1. เข้า **Category Editor** → เลือก Category  
2. ดูหัวตาราง จะเห็น **👁️⃠ icon** (visibility_off)
3. **Check ✅** ใต้ icon นี้สำหรับ fields ที่ต้องการซ่อน
4. Fields ที่ check จะถูกมาสก์เป็น `*****` ในหน้าอื่นๆ
