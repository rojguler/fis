# 🔥 Firebase Authentication Hatası Çözümü

## ❌ Sorun: "Authentication failed unknown"

Bu hata Firebase yapılandırması eksik olduğu için oluşuyor.

## ✅ Çözüm: Firebase Yapılandırması (5 Dakika)

### 1️⃣ Firebase Console'da Proje Oluştur

1. **https://console.firebase.google.com/** adresine git
2. **"Add project"** (Proje Ekle) tıkla
3. Proje adı: `ikas-fis`
4. Google Analytics'i atla (Skip)
5. **"Create project"** tıkla

### 2️⃣ Android Uygulaması Ekle

1. Firebase Console'da projeni aç
2. Ana sayfada **Android ikonu**'na tıkla
3. **Package name**: `com.example.ikas_fis` (yapıştır)
4. **Register app** tıkla
5. **google-services.json** dosyasını **İNDİR**

### 3️⃣ Dosyaları Kopyala

**İndirdiğin `google-services.json` dosyasını şuraya kopyala:**
```
C:\Users\Rojin\Desktop\ikas\android\app\google-services.json
```

### 4️⃣ Firebase Bilgilerini Kopyala

1. Firebase Console'da: **⚙️ Project settings** > **Your apps** > **Android app**
2. **"Config"** butonuna tıkla
3. Aşağıdaki değerleri kopyala:
   - `apiKey`
   - `appId` (mobilesdk_app_id)
   - `messagingSenderId` (project_number)
   - `projectId`
   - `storageBucket`

### 5️⃣ firebase_options.dart Dosyasını Güncelle

`lib/firebase_options.dart` dosyasını aç ve şu satırları bul:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDummyKeyReplaceWithYourRealKey123456789',  // ← Buraya yapıştır
  appId: '1:123456789:android:abcdef123456789',            // ← Buraya yapıştır
  messagingSenderId: '123456789',                          // ← Buraya yapıştır
  projectId: 'ikas-fis',                                    // ← Buraya yapıştır
  storageBucket: 'ikas-fis.appspot.com',                    // ← Buraya yapıştır
);
```

Firebase Console'dan kopyaladığın değerleri yukarıdaki yerlere yapıştır.

### 6️⃣ Google Services Plugin'ini Aktif Et

`android/app/build.gradle.kts` dosyasını aç ve 8. satırdaki `//` işaretini kaldır:

```kotlin
id("com.google.gms.google-services")  // ← Bu satırın başındaki // işaretini kaldır
```

### 7️⃣ Authentication'ı Aç

1. Firebase Console'da: **Authentication** > **Get started**
2. **Sign-in method** sekmesine git
3. **Email/Password** satırına tıkla
4. **Enable** yap ve **Save** tıkla

### 8️⃣ Uygulamayı Yeniden Başlat

```bash
flutter run
```

---

## ✅ Tamamlandı!

Artık giriş yapabilirsiniz:
- Yeni hesap oluşturabilirsiniz (Sign Up)
- Giriş yapabilirsiniz (Login)

---

## 🆘 Hala Çalışmıyorsa

1. **Firebase Console'da Authentication açık mı?** Kontrol et
2. **google-services.json dosyası doğru yerde mi?** `android/app/` klasöründe olmalı
3. **firebase_options.dart değerleri doğru mu?** Firebase Console'dan kopyaladığın değerlerle eşleşmeli
4. **Uygulamayı tamamen kapatıp yeniden aç** (hot restart yap)

