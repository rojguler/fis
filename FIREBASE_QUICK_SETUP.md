# Firebase Hızlı Kurulum (5 Dakika)

## ⚡ Hızlı Adımlar

### 1. Firebase Console'da Proje Oluştur
1. https://console.firebase.google.com/ adresine git
2. "Add project" (Proje Ekle) tıkla
3. Proje adı: `ikas-fis` (veya istediğin isim)
4. Google Analytics'i atla (Skip)
5. "Create project" tıkla

### 2. Android Uygulaması Ekle
1. Firebase Console'da projeni aç
2. Ana sayfada Android ikonuna tıkla (veya ⚙️ > Project settings > Your apps > Add app > Android)
3. **Package name**: `com.example.ikas_fis` (bu değeri kopyala)
4. "Register app" tıkla
5. **`google-services.json` dosyasını indir**
6. İndirilen dosyayı `android/app/` klasörüne kopyala

### 3. Authentication'ı Aç
1. Sol menüden "Authentication" seç
2. "Get started" tıkla
3. "Sign-in method" sekmesine git
4. "Email/Password" satırına tıkla
5. "Enable" yap ve "Save" tıkla

### 4. Firestore Database'i Aç
1. Sol menüden "Firestore Database" seç
2. "Create database" tıkla
3. "Start in test mode" seç (geliştirme için)
4. Location seç (örn: `europe-west`)
5. "Enable" tıkla

### 5. Firebase Bilgilerini Kopyala
1. ⚙️ > Project settings > Your apps > Android app
2. "Config" butonuna tıkla
3. Aşağıdaki değerleri kopyala:
   - `apiKey`
   - `appId` (mobilesdk_app_id)
   - `messagingSenderId` (project_number)
   - `projectId`
   - `storageBucket`

### 6. `lib/firebase_options.dart` Dosyasını Güncelle
`lib/firebase_options.dart` dosyasını aç ve kopyaladığın değerleri yapıştır:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'BURAYA_API_KEY_YAPIŞTIR',
  appId: 'BURAYA_APP_ID_YAPIŞTIR',
  messagingSenderId: 'BURAYA_SENDER_ID_YAPIŞTIR',
  projectId: 'BURAYA_PROJECT_ID_YAPIŞTIR',
  storageBucket: 'BURAYA_STORAGE_BUCKET_YAPIŞTIR',
);
```

### 7. Test Et
```bash
flutter pub get
flutter run
```

## ✅ Tamamlandı!

Artık Firebase hazır. Uygulama çalıştığında:
- Login/Sign up ekranları çalışacak
- Firestore'a veri yazıp okuyabileceksin

## 📝 İlk Veriyi Ekle

Firestore'da `meals` koleksiyonunu oluştur ve örnek yemek ekle:

1. Firestore Database > Start collection
2. Collection ID: `meals`
3. Document ID: otomatik oluştur
4. Fields ekle:
   - `name` (string): "Grilled Chicken"
   - `description` (string): "Tender grilled chicken"
   - `price` (number): 25.50
   - `calories` (number): 350
   - `nutrients` (map): 
     - `protein`: 30.0
     - `carbs`: 5.0
     - `fat`: 20.0
   - `allergens` (array): ["gluten"]
   - `stock` (number): 50
   - `imageUrl` (string): ""
   - `category` (string): "main"

