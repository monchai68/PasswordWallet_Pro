# 🔧 ขั้นตอนการตั้งค่า Google Drive สำหรับ Password Wallet Pro

## ✅ ข้อมูลสำคัญที่ได้จากระบบ:

**📋 Package Name:** `com.example.password_manager_simple`  
**🔑 SHA-1 Fingerprint:** `2D:0C:26:4C:A6:7C:B1:5A:5C:93:0B:E0:76:5E:C4:EE:09:86:71:32`  
**🆔 Project ID:** `password-wallet-pro`  
**📱 Client ID:** `1015238157429-ju9a2gc9idbg3c809t45b6m2tnl1huqn.apps.googleusercontent.com`  
**🔑 API Key:** `AIzaSyD_MLtLvgcGZzwf44ug_--jXuVxhxl440M`

---

## 🚀 ขั้นตอนการตั้งค่า Google Cloud Console:

### 1. ตรวจสอบโปรเจ็กต์ใน Google Cloud Console
1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. เลือกโปรเจ็กต์ **`password-wallet-pro`** (หรือสร้างใหม่หากยังไม่มี)
3. ตรวจสอบว่า Project ID เป็น **`password-wallet-pro`**

### 2. เปิดใช้งาน Google Drive API
1. ไปที่ **"APIs & Services"** → **"Library"**
2. ค้นหา **"Google Drive API"**
3. คลิก **"Enable"**

### 3. ตั้งค่า OAuth Consent Screen
1. ไปที่ **"APIs & Services"** → **"OAuth consent screen"**
2. เลือก **"External"** (สำหรับผู้ใช้ทั่วไป)
3. กรอกข้อมูล:
   - **App name:** `Password Wallet Pro`
   - **User support email:** อีเมลของคุณ
   - **Developer contact information:** อีเมลของคุณ
4. ในหน้า **"Scopes"** ให้เพิ่ม:
   - `../auth/drive.file` (เพื่อเข้าถึงไฟล์ที่แอปสร้างขึ้น)
   - `../auth/userinfo.email` (เพื่อดูอีเมลของผู้ใช้)
5. ในหน้า **"Test users"** ให้เพิ่มอีเมล Google ที่จะใช้ทดสอบ

### 4. สร้าง OAuth 2.0 Client ID
1. ไปที่ **"APIs & Services"** → **"Credentials"**
2. คลิก **"Create Credentials"** → **"OAuth client ID"**
3. เลือกประเภท **"Android"**
4. กรอกข้อมูล:
   - **Name:** `Password Wallet Pro Android`
   - **Package name:** `com.example.password_manager_simple`
   - **SHA-1 certificate fingerprint:** `2D:0C:26:4C:A6:7C:B1:5A:5C:93:0B:E0:76:5E:C4:EE:09:86:71:32`
5. คลิก **"Create"**

### 5. ตรวจสอบไฟล์ google-services.json
ไฟล์ `google-services.json` ได้ถูกสร้างและกำหนดค่าเรียบร้อยแล้วด้วยข้อมูลต่อไปนี้:
- **Project ID:** `password-wallet-pro`
- **Client ID:** `1015238157429-ju9a2gc9idbg3c809t45b6m2tnl1huqn.apps.googleusercontent.com`
- **API Key:** `AIzaSyD_MLtLvgcGZzwf44ug_--jXuVxhxl440M`
- **Package Name:** `com.example.password_manager_simple`
- **SHA-1 Hash:** `2d0c264ca67cb15a5c930be0765ec4ee09867132`

✅ **ไฟล์นี้พร้อมใช้งานแล้ว** ไม่ต้องแก้ไขเพิ่มเติม

### 6. ตั้งค่าที่เหลือใน Google Cloud Console
ตอนนี้คุณต้องดำเนินการขั้นตอนต่อไปนี้ใน Google Cloud Console:

1. **เปิดใช้งาน Google Drive API** (ขั้นตอนที่ 2)
2. **ตั้งค่า OAuth Consent Screen** (ขั้นตอนที่ 3)
3. **สร้าง OAuth 2.0 Client ID** พร้อมเพิ่ม SHA-1 fingerprint (ขั้นตอนที่ 4)
4. **เพิ่ม Test Users** ในการตั้งค่า OAuth consent screen

---

## 🧪 ทดสอบการตั้งค่า:

หลังจากทำตามขั้นตอนข้างต้นแล้ว:

1. **รอ 5-10 นาที** เพื่อให้ Google อัปเดตการตั้งค่า
2. แอปพลิเคชันพร้อมทดสอบแล้ว - ไม่ต้องรันคำสั่งเพิ่มเติม
3. ไปที่ **Settings** → **"Sync to cloud"**
4. ลองกด **Sign in to Google Drive**

✅ **ไฟล์ google-services.json และ API Key ได้ถูกกำหนดค่าเรียบร้อยแล้ว**

---

## 🐛 การแก้ไขปัญหาที่อาจเกิดขึ้น:

### ❌ หากยังคงได้ Error Code 10:
- **ตรวจสอบ SHA-1:** ใช้ค่า `2D:0C:26:4C:A6:7C:B1:5A:5C:93:0B:E0:76:5E:C4:EE:09:86:71:32`
- **ตรวจสอบ Package Name:** ต้องเป็น `com.example.password_manager_simple`
- **รอ 5-10 นาที** หลังจากเพิ่ม SHA-1
- **ลอง flutter clean** แล้วรันใหม่

### ❌ หากได้ Error Code 12:
- เพิ่มอีเมล Google ของคุณใน **"Test users"** ใน OAuth consent screen

### ❌ หากได้ Network Error:
- ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต
- ตรวจสอบว่า Google Drive API ถูกเปิดใช้งานแล้ว

---

## 📝 หมายเหตุสำคัญ:

1. **ไฟล์ google-services.json:** ✅ **พร้อมใช้งาน** - ได้ถูกกำหนดค่าด้วย API Key ที่แท้จริงแล้ว
2. **API Key:** ✅ **ครบถ้วน** - `AIzaSyD_MLtLvgcGZzwf44ug_--jXuVxhxl440M`
3. **Client ID:** ✅ **พร้อมใช้งาน** - `1015238157429-ju9a2gc9idbg3c809t45b6m2tnl1huqn.apps.googleusercontent.com`
4. **SHA-1 Fingerprint:** ✅ **ถูกต้อง** - ได้จากระบบและเพิ่มในไฟล์แล้ว
5. **แอปพลิเคชัน:** ✅ **Build สำเร็จ** - พร้อมทดสอบ Google Drive integration
4. **อีเมลทดสอบ:** ในขั้นตอนการพัฒนา ระบบจะยอมรับเฉพาะอีเมลที่เพิ่มใน "Test users" เท่านั้น
5. **การเผยแพร่:** เมื่อพร้อมเผยแพร่แอป จะต้องส่ง OAuth consent screen ให้ Google ตรวจสอบ
6. **ความปลอดภัย:** ไฟล์ `google-services.json` มีข้อมูลสำคัญ ไม่ควรแชร์ในที่สาธารณะ

---

## 📞 ต้องการความช่วยเหลือ:

หากยังมีปัญหา:
1. ตรวจสอบ error message ในแอป (จะมีคำแนะนำเฉพาะ)
2. ตรวจสอบว่าทำตามขั้นตอนครบถ้วนแล้ว
3. รอ 5-10 นาทีหลังจากการเปลี่ยนแปลงการตั้งค่า

**ขั้นตอนนี้เป็นการตั้งค่าครั้งเดียว หลังจากตั้งค่าเสร็จแล้ว ผู้ใช้จะสามารถใช้งาน Google Drive backup ได้ตามปกติ** ✅
