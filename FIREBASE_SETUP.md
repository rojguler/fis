# Firebase Kurulum Rehberi

Bu dosya, IKAS Food Information System projesi için Firebase'i nasıl kuracağınızı açıklar.

## Adım 1: Firebase Projesi Oluşturma

1. [Firebase Console](https://console.firebase.google.com/) adresine gidin
2. "Add project" (Proje Ekle) butonuna tıklayın
3. Proje adını girin (örn: "ikas-fis")
4. Google Analytics'i isteğe bağlı olarak etkinleştirin
5. "Create project" (Proje Oluştur) butonuna tıklayın

## Adım 2: Android Uygulaması Ekleme

1. Firebase Console'da projenizi açın
2. Sol menüden "Project settings" (⚙️) > "Your apps" bölümüne gidin
3. Android ikonuna tıklayın
4. Aşağıdaki bilgileri girin:
   - **Android package name**: `com.example.ikas_fis`
   - **App nickname** (isteğe bağlı): IKAS FIS
   - **Debug signing certificate SHA-1** (isteğe bağlı, şimdilik atlayabilirsiniz)
5. "Register app" butonuna tıklayın
6. `google-services.json` dosyasını indirin
7. İndirilen `google-services.json` dosyasını `android/app/` klasörüne kopyalayın

## Adım 3: iOS Uygulaması Ekleme (Opsiyonel)

1. Firebase Console'da "Add app" > iOS ikonuna tıklayın
2. Aşağıdaki bilgileri girin:
   - **iOS bundle ID**: `com.example.ikasFis`
   - **App nickname** (isteğe bağlı): IKAS FIS
3. "Register app" butonuna tıklayın
4. `GoogleService-Info.plist` dosyasını indirin
5. İndirilen dosyayı `ios/Runner/` klasörüne kopyalayın

## Adım 4: Firebase Servislerini Etkinleştirme

### Authentication (Kimlik Doğrulama)

1. Firebase Console'da sol menüden "Authentication" seçin
2. "Get started" butonuna tıklayın
3. "Sign-in method" (Giriş yöntemleri) sekmesine gidin
4. "Email/Password" seçeneğini etkinleştirin
5. "Enable" butonuna tıklayın ve "Save" yapın

### Cloud Firestore (Veritabanı)

1. Firebase Console'da sol menüden "Firestore Database" seçin
2. "Create database" butonuna tıklayın
3. "Start in test mode" seçeneğini seçin (geliştirme için)
4. Cloud Firestore location seçin (örn: `europe-west`)
5. "Enable" butonuna tıklayın

## Adım 5: Firestore Koleksiyonlarını Oluşturma

### Meals Koleksiyonu

1. Firestore Database'de "Start collection" butonuna tıklayın
2. Collection ID: `meals`
3. İlk doküman için örnek veri:

```json
{
  "name": "Grilled Chicken",
  "description": "Tender grilled chicken with herbs",
  "price": 25.50,
  "calories": 350,
  "nutrients": {
    "protein": 30.0,
    "carbs": 5.0,
    "fat": 20.0
  },
  "allergens": ["gluten"],
  "stock": 50,
  "imageUrl": "",
  "category": "main"
}
```

### Menus Koleksiyonu

1. "Start collection" butonuna tıklayın
2. Collection ID: `menus`
3. İlk doküman için örnek veri:

```json
{
  "date": "2024-01-15T00:00:00Z",
  "mealIds": ["meal_document_id_1", "meal_document_id_2"],
  "cafeteriaId": "ikas_main"
}
```

**Not**: `mealIds` array'inde, `meals` koleksiyonundaki gerçek doküman ID'lerini kullanın.

## Adım 6: Firebase Yapılandırma Dosyasını Güncelleme

1. Firebase Console'da "Project settings" > "Your apps" bölümüne gidin
2. Android uygulamanızın yanındaki "Config" butonuna tıklayın
3. `firebase_options.dart` dosyasındaki değerleri güncelleyin:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY', // Config'den kopyalayın
  appId: 'YOUR_ANDROID_APP_ID',   // Config'den kopyalayın
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID', // Config'den kopyalayın
  projectId: 'YOUR_PROJECT_ID',   // Config'den kopyalayın
  storageBucket: 'YOUR_STORAGE_BUCKET', // Config'den kopyalayın
);
```

## Adım 7: FlutterFire CLI ile Otomatik Yapılandırma (Alternatif)

Eğer FlutterFire CLI kullanmak isterseniz:

```bash
# FlutterFire CLI'yi yükleyin (zaten yüklü)
dart pub global activate flutterfire_cli

# Firebase'e giriş yapın
firebase login

# Projeyi yapılandırın
flutterfire configure
```

Bu komut otomatik olarak `firebase_options.dart` dosyasını oluşturur.

## Adım 8: Uygulamayı Çalıştırma

```bash
# Bağımlılıkları yükleyin
flutter pub get

# Uygulamayı çalıştırın
flutter run
```

## Güvenlik Kuralları (Firestore)

Geliştirme aşamasında test mode kullanabilirsiniz, ancak production için güvenlik kuralları ekleyin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Meals koleksiyonu - herkes okuyabilir
    match /meals/{mealId} {
      allow read: if true;
      allow write: if request.auth != null; // Sadece giriş yapmış kullanıcılar yazabilir
    }
    
    // Menus koleksiyonu - herkes okuyabilir
    match /menus/{menuId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Sorun Giderme

### "DefaultFirebaseOptions are not supported for this platform" hatası
- `firebase_options.dart` dosyasındaki değerlerin doğru olduğundan emin olun
- `google-services.json` dosyasının `android/app/` klasöründe olduğunu kontrol edin

### Authentication çalışmıyor
- Firebase Console'da Email/Password authentication'ın etkin olduğunu kontrol edin
- `firebase_options.dart` dosyasındaki API key'lerin doğru olduğundan emin olun

### Firestore bağlantı hatası
- Firestore Database'in oluşturulduğunu kontrol edin
- İnternet bağlantınızı kontrol edin
- Firestore güvenlik kurallarını kontrol edin

## Yardım

Daha fazla bilgi için:
- [FlutterFire Dokümantasyonu](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)

