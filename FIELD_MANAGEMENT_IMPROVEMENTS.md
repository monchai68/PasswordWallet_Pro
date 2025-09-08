# Item Detail Screen - Field Management System

## ปรับปรุงการจัดการ Field ใน Item Detail Screen

### ปัญหาที่แก้ไข:

1. **การเปลี่ยนชื่อ Field**: เมื่อแก้ไขชื่อ field ใน category editor ข้อมูลเดิมจะหายไป
2. **การจัดลำดับใหม่**: ลำดับการแสดงผลไม่เปลี่ยนตามการจัดลำดับใหม่ใน category editor
3. **Field ใหม่**: item เก่าไม่แสดง field ใหม่ที่เพิ่มเข้ามาทีหลัง

### ฟีเจอร์ใหม่:

#### 1. Dynamic Field Loading
- โหลด field structure จาก category configuration
- แสดงผลตามลำดับที่กำหนดใน category editor
- รองรับการเปลี่ยนแปลง field configuration แบบ real-time

#### 2. Field Name Migration
- ระบบ mapping ชื่อ field เก่า-ใหม่อัตโนมัติ
- รองรับชื่อ field ทั่วไป เช่น:
  - Name: ['name', 'title', 'item_name']
  - Login: ['login', 'username', 'user', 'email']
  - Password: ['password', 'pass', 'pwd']
  - Email: ['email', 'e-mail', 'mail']
  - Note: ['note', 'notes', 'description', 'desc']
  - URL: ['url', 'website', 'link']
  - Phone: ['phone', 'telephone', 'mobile']

#### 3. Smart Field Display
- แสดง field ที่ไม่มีข้อมูลเป็น "(No data)"
- สามารถ copy field ที่มีข้อมูลเท่านั้น
- แสดง/ซ่อน password field เฉพาะที่มีข้อมูล

#### 4. Automatic Data Migration
- อัปเดตข้อมูลเก่าให้เข้ากับ field structure ใหม่
- ลบชื่อ field เก่าที่ไม่ใช้แล้ว
- บันทึกข้อมูลที่ migrate แล้วกลับฐานข้อมูล

### การใช้งาน:

1. **เมื่อแก้ไขชื่อ field ใน category editor**:
   - ข้อมูลเดิมจะถูก migrate ไปยังชื่อใหม่อัตโนมัติ
   - แสดงผลด้วยชื่อ field ใหม่ทันที

2. **เมื่อจัดลำดับ field ใหม่**:
   - ลำดับการแสดงผลจะเปลี่ยนตามการตั้งค่าใน category editor
   - ไม่ต้อง restart แอปหรือรีเฟรชข้อมูล

3. **เมื่อเพิ่ม field ใหม่**:
   - item เก่าจะแสดง field ใหม่เป็น "(No data)"
   - สามารถแก้ไขเพื่อเพิ่มข้อมูลใน field ใหม่ได้

### ไฟล์ที่แก้ไข:
- `lib/screens/item_detail_screen.dart`

### Methods ใหม่:
- `_loadCategoryFields()`: โหลด field structure จาก category
- `_getFieldValue()`: ดึงข้อมูลพร้อม fallback mapping
- `_migrateFieldNames()`: migrate ข้อมูลเก่าไปยัง field ใหม่
- `_initializeData()`: เริ่มต้นข้อมูลและ migration

### ผลลัพธ์:
- Item Detail Screen จะแสดงผลตาม field configuration ปัจจุบันเสมอ
- ข้อมูลเก่าไม่หายหายเมื่อแก้ไข category structure
- รองรับการเปลี่ยนแปลง field แบบ backward compatible
