# Search Icon Implementation in Category Password List

## 🎯 การอัปเดต Icon ในหน้า Category Password List

### ปัญหาเดิม:
- ในหน้าที่แสดง item list ของแต่ละ category มี icon grid (9 จุด) บน AppBar 
- ผู้ใช้ต้องการเปลี่ยนเป็น icon แว่นขยาย สำหรับ search หา item

### ✅ การแก้ไขที่ทำ:

#### เปลี่ยน Icon ใน AppBar Actions:
```dart
// ไฟล์: lib/screens/category_password_list_screen.dart

// เดิม
actions: [
  IconButton(
    icon: const Icon(Icons.apps, color: Colors.white),
    onPressed: () {
      // Menu action
    },
  ),
],

// ใหม่
actions: [
  IconButton(
    icon: const Icon(Icons.search, color: Colors.white),
    onPressed: () {
      // Search action - TODO: Implement search functionality
    },
  ),
],
```

### 🎨 **การเปลี่ยนแปลง:**

#### Icon ที่เปลี่ยน:
- **เดิม**: `Icons.apps` (🔵🔵🔵 grid 9 จุด)
- **ใหม่**: `Icons.search` (🔍 แว่นขยาย)

#### ตำแหน่ง:
- **หน้า**: Category Password List Screen (หน้าที่แสดง items ในแต่ละ category)
- **ตำแหน่ง**: AppBar actions (มุมขวาบน)

### 📱 **หน้าที่ได้รับผลกระทบ:**

```
หน้า Category Password List:
┌─────────────────────────────────────┐
│ ← Web Accounts            🔍       │ ← AppBar
├─────────────────────────────────────┤
│ กรมสรรพากร                           │
│ ข่าวหุ้น                             │
│ ประกันสังคม www.sso.go.th           │
│ ฟิสิกส์โก เอก                        │
│ เภสัชกรรมสมาคม                        │
│ ศูนย์การศึกษาต่อเรื่องเภสัชศาสตร์      │
│ Adobe photoshop                     │
│ AIS Bookstore                       │
│ Ali Express                         │
│ Amazon buyer                        │
│ Amazon seller                       │
└─────────────────────────────────────┘
```

### 🔄 **การทำงาน:**

1. **เมื่อกดไอคอน search**: จะเรียกใช้ฟังก์ชัน search (ยังไม่ได้ implement)
2. **การเตรียมพร้อม**: เพิ่มคอมเมนต์ TODO เพื่อ implement search functionality ในอนาคต

### 🚀 **ประโยชน์:**

- **ชัดเจนขึ้น**: ผู้ใช้เข้าใจทันทีว่าไอคอนนี้สำหรับ search
- **UI สวยงาม**: แว่นขยายเป็น icon มาตรฐานสำหรับการค้นหา
- **เตรียมพร้อม**: พร้อมสำหรับการ implement search functionality

### 📁 **ไฟล์ที่แก้ไข:**
- `lib/screens/category_password_list_screen.dart`
  - เปลี่ยน AppBar actions icon จาก `Icons.apps` เป็น `Icons.search`
  - อัปเดตคอมเมนต์จาก "Menu action" เป็น "Search action"
  - เพิ่ม TODO สำหรับ implement search functionality

### ✨ **ผลลัพธ์:**

ตอนนี้เมื่อเข้าไปดู items ในแต่ละ category จะเห็น **icon แว่นขยาย** (🔍) บน AppBar แทนที่จะเป็น icon grid เดิม! 

### 🔧 **การใช้งาน:**
1. เข้าหน้า **Categories** → เลือก category ใดๆ
2. จะเข้าไปหน้า **Category Password List**
3. ดูมุมขวาบนของ AppBar จะเห็น **🔍 icon แว่นขยาย**
4. กดได้แต่ยังไม่มี search functionality (รอ implement)

### 📝 **Next Steps:**
- Implement search functionality เมื่อกด search icon
- เพิ่ม search bar หรือ dialog สำหรับพิมพ์คำค้นหา
- Filter items ตามชื่อหรือข้อมูลในฟิลด์ต่างๆ
