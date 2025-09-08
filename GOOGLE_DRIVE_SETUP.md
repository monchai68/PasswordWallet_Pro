# การแก้ไขปัญหา Google Drive Sign-In

## ❌ ปัญหา: "Failed to sign in to Google Drive"

### 🔍 สาเหตุหลัก:
1. **ยังไม่ได้ตั้งค่า Google Cloud Console**
2. **ไม่มี Google Services configuration**

---

## ✅ วิธีแก้ไข (ทำตามลำดับ):

### **สถานะปัจจุบัน:** 
✅ แอปสามารถรันได้แล้ว (ปิดการใช้งาน Google Services ชั่วคราว)
⚠️  Google Drive Sign-In จะยังใช้งานไม่ได้จนกว่าจะตั้งค่าเสร็จ

### 1. สร้างโปรเจ็กต์ใน Google Cloud Console
1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/)
2. คลิก "Create Project" หรือเลือกโปรเจ็กต์ที่มีอยู่
3. จดชื่อโปรเจ็กต์ไว้

### 2. เปิดใช้งาน Google Drive API
1. ใน Google Cloud Console ไปที่ "APIs & Services" > "Library"
2. ค้นหา "Google Drive API"
3. คลิก "Enable"

### 3. หา SHA-1 Fingerprint
```bash
cd android
gradlew.bat signingReport
```
จดค่า SHA1 ที่ขึ้นมา (จะเป็นแบบ: `AB:CD:EF:12:34:...`)

### 4. ตั้งค่า OAuth Consent Screen
1. ไปที่ "APIs & Services" > "OAuth consent screen"
2. เลือก "External" 
3. กรอก:
   - App name: `PasswordWallet Pro`
   - User support email: อีเมลของคุณ
   - Developer contact information: อีเมลของคุณ
4. คลิก "Save and Continue"
5. ในหน้า "Scopes" คลิก "Save and Continue"
6. ในหน้า "Test users" เพิ่มอีเมล Google ที่จะใช้ทดสอบ

### 5. สร้าง OAuth 2.0 Client ID
1. ไปที่ "APIs & Services" > "Credentials"
2. คลิก "Create Credentials" > "OAuth client ID"
3. เลือก "Android"
4. กรอก:
   - Name: `PasswordWallet Android`
   - Package name: `com.example.password_manager_simple`
   - SHA-1: ใส่ค่าที่ได้จากขั้นตอนที่ 3
5. คลิก "Create"

### 6. ดาวน์โหลด google-services.json
1. ไปที่ "Project Settings" (ไอคอนเฟือง)
2. เลือกแท็บ "General"
3. ในส่วน "Your apps" ให้คลิก Android app
4. คลิก "Download google-services.json"
5. **สำคัญ**: คัดลอกไฟล์นี้ไปวางใน `android/app/` 
   (แทนที่ไฟล์ที่มีอยู่)

### 7. เปิดใช้งาน Google Services
หลังจากได้ไฟล์ `google-services.json` จริงแล้ว:

1. แก้ไข `android/build.gradle.kts`:
```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

2. แก้ไข `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // uncomment this line
}
```

### 8. ทดสอบ
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🐛 การแก้ไขปัญหาเพิ่มเติม:

### ข้อความ Error ที่อาจพบ:

#### Error Code 10 (DEVELOPER_ERROR)
- **สาเหตุ**: การตั้งค่า Google Cloud Console ไม่ถูกต้อง
- **แก้ไข**:
  1. ตรวจสอบ SHA-1 fingerprint ในขั้นตอนที่ 3
  2. ตรวจสอบ package name: `com.example.password_manager_simple`
  3. ตรวจสอบว่า OAuth client สำหรับ Android ถูกสร้างแล้ว
  4. ตรวจสอบไฟล์ `google-services.json` ว่าอยู่ในตำแหน่งที่ถูกต้อง

#### Error Code 12 (INVALID_ACCOUNT)
- **สาเหตุ**: บัญชี Google ไม่ได้เพิ่มใน Test users
- **แก้ไข**: เพิ่มบัญชี Google ในขั้นตอนที่ 4 (Test users)

#### Error Code 7 (NETWORK_ERROR)
- **สาเหตุ**: ปัญหาเครือข่ายหรือ API ไม่ได้เปิดใช้งาน
- **แก้ไข**: ตรวจสอบอินเทอร์เน็ต และเปิดใช้งาน Google Drive API

#### "User cancelled sign in"
- **สาเหตุ**: ผู้ใช้กดยกเลิกการ sign in
- **แก้ไข**: ลองอีกครั้ง

#### "Failed to sign in to Google Drive"
- **สาเหตุ**: ยังไม่ได้ตั้งค่า Google Cloud Console
- **แก้ไข**: ทำตามขั้นตอนที่ 1-7

### เคล็ดลับการ Debug:
1. **ดู Error Dialog ในแอป**: ระบบจะแสดงรหัส error และวิธีแก้ไขเฉพาะ
2. **ตรวจสอบ SHA-1**: รันคำสั่ง `cd android && gradlew.bat signingReport`
3. **รอหลังตั้งค่า**: Google อาจใช้เวลา 5-10 นาทีในการอัปเดต
4. **ใช้บัญชีทดสอบ**: ใช้บัญชี Google ที่เพิ่มใน Test users เท่านั้น

### หากยังมีปัญหา:
1. ตรวจสอบ package name ให้ตรงกัน
2. ตรวจสอบ SHA-1 fingerprint
3. รอ 5-10 นาทีหลังจากตั้งค่าใหม่
4. ลอง `flutter clean` และรันใหม่

### ดู error logs:
- เปิด terminal และดู messages ที่ขึ้นมา
- ใน VS Code ดูที่ Debug Console

### Contact:
หากยังมีปัญหาให้ส่ง error message ที่ได้มาครับ
