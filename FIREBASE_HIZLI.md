# 🔥 Firebase Hızlı Kurulum (Test İçin)

## ⚡ 5 Dakikada Firebase Kurulumu

### 1. Firebase Console
1. https://console.firebase.google.com/ → Giriş yap
2. **"Add project"** (Proje Ekle) tıkla
3. Proje adı: `ikas-fis` → **Create project**

### 2. Android App Ekle
1. Firebase Console'da projeni aç
2. Ana sayfada **Android ikonu**'na tıkla
3. **Package name**: `com.example.ikas_fis` (yapıştır)
4. **Register app** tıkla
5. **google-services.json** dosyasını **İNDİR**

### 3. Dosyayı Kopyala
İndirdiğin `google-services.json` dosyasını şu klasöre kopyala:
```
C:\Users\Rojin\Desktop\ikas\android\app\google-services.json
```

### 4. Plugin'i Aktif Et
`android/app/build.gradle.kts` dosyasında şu satırın başındaki `//` işaretini kaldır:
```kotlin
id("com.google.gms.google-services")  // Bu satırı aktif et
```

### 5. Tekrar Dene
```bash
flutter run
```

---

## ✅ Tamamlandı!

Artık Firebase çalışacak ve uygulama telefona yüklenecek.

**Not**: Authentication ve Firestore'u da açmayı unutma:
- Authentication → Email/Password → Enable
- Firestore Database → Create database → Test mode

