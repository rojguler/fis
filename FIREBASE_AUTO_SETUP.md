# 🔥 Firebase Otomatik Kurulum

## ⚡ Hızlı Başlangıç (3 Adım)

### 1️⃣ Firebase Console'da Proje Oluştur
1. https://console.firebase.google.com/ → "Add project"
2. Proje adı: `ikas-fis`
3. Analytics'i atla → "Create project"

### 2️⃣ Android App Ekle ve Dosyayı İndir
1. Firebase Console'da Android ikonuna tıkla
2. Package name: `com.example.ikas_fis`
3. "Register app" → `google-services.json` dosyasını indir
4. **İndirilen dosyayı `android/app/` klasörüne kopyala**

### 3️⃣ Firebase Bilgilerini Kopyala
1. Firebase Console > ⚙️ Project settings > Your apps > Android app
2. "Config" butonuna tıkla
3. Aşağıdaki değerleri kopyala ve `lib/firebase_options.dart` dosyasına yapıştır:

```dart
// lib/firebase_options.dart dosyasında şu satırları bul:
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'BURAYA_API_KEY',           // Config'den kopyala
  appId: 'BURAYA_APP_ID',             // Config'den kopyala  
  messagingSenderId: 'BURAYA_SENDER', // Config'den kopyala
  projectId: 'BURAYA_PROJECT_ID',    // Config'den kopyala
  storageBucket: 'BURAYA_BUCKET',     // Config'den kopyala
);
```

### 4️⃣ Servisleri Aç
- **Authentication**: Email/Password'u etkinleştir
- **Firestore**: Test mode'da oluştur

## ✅ Tamamlandı!

```bash
flutter pub get
flutter run
```

## 📝 İlk Veriyi Ekle (Opsiyonel)

Firestore'da `meals` koleksiyonunu oluştur:
- Collection ID: `meals`
- Document fields:
  - name (string): "Grilled Chicken"
  - price (number): 25.50
  - calories (number): 350
  - stock (number): 50
  - category (string): "main"
  - allergens (array): ["gluten"]
  - nutrients (map): {protein: 30.0, carbs: 5.0, fat: 20.0}

