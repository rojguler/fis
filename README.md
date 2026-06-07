# iKAS Fis — Akıllı Yemekhane Sipariş Sistemi

<p align="center">
  <img src="assets/images/app_logo.png" alt="iKAS Fis Logo" width="120"/>
</p>

<p align="center">
  <strong>İKAS Üniversitesi Kafeterya Uygulaması</strong><br>
  Flutter · Firebase · Real-Time Orders · Admin Dashboard
</p>

---

## 📖 Genel Bakış

**iKAS Fis**, üniversite kafeteryaları için tasarlanmış, gerçek zamanlı sipariş takibi ve yönetimi sunan bir Flutter mobil uygulamasıdır. Öğrenciler yemek menüsünü inceleyebilir, sipariş verebilir ve siparişlerini anlık olarak takip edebilirken; kafeterya personeli/admini gelen siparişleri yönetebilir.

---

## 🚀 Özellikler

### Kullanıcı Tarafı
| Özellik | Açıklama |
|--------|----------|
| 🔐 **Kimlik Doğrulama** | E-posta/şifre ve Google ile giriş |
| 🍽️ **Menü İnceleme** | Kategori filtreli, besin değerli menü görüntüleme |
| 🔍 **Arama** | Yemek adı ve açıklamasına göre anlık arama |
| 🛒 **Sepet Yönetimi** | Çoklu ürün, miktar güncelleme, kupon uygulama |
| 📦 **Sipariş Oluşturma** | Not ekleyebilme, sipariş numarası otomatik atanır |
| 📍 **Sipariş Takibi** | Firestore real-time stream ile anlık durum güncellemesi |
| ⭐ **Değerlendirme** | Tamamlanan siparişler için yorum & yıldız sistemi |
| 🔁 **Yeniden Sipariş** | Önceki siparişi tek tıkla tekrarlama |
| 🎫 **Kupon Sistemi** | Yüzde indirim (FIS10) ve sabit indirim (WELCOME25) kuponları |
| 🌙 **Karanlık Mod** | Açık/koyu tema desteği |
| 🌐 **Dil Desteği** | Türkçe / İngilizce çeviri |
| 👤 **Profil** | Sipariş geçmişi, istatistikler, profil düzenleme |

### Admin Tarafı
| Özellik | Açıklama |
|--------|----------|
| 📋 **Sipariş Yönetimi** | Tüm aktif siparişleri görme ve durum güncelleme |
| 🍴 **Menü Yönetimi** | Yemek ekleme, düzenleme, silme; stok ve fiyat kontrolü |
| 🎟️ **Kupon Yönetimi** | Kupon oluşturma, aktif/pasif yapma, silme |
| 📊 **İstatistikler** | Toplam sipariş sayısı, günlük gelir, popüler ürünler |
| 🔔 **Bildirimler** | FCM ile push notification desteği |

---

## 🏗️ Teknik Mimari

```
lib/
├── main.dart                    # App entry, Provider setup, deep link
├── models/
│   ├── meal.dart                # Yemek modeli (besin, alerjen, stok)
│   ├── order.dart               # Sipariş modeli + OrderStatus enum
│   ├── cart_item.dart           # Sepet öğesi
│   ├── review.dart              # Değerlendirme modeli
│   ├── menu.dart                # Menü modeli
│   └── supplier.dart            # Tedarikçi modeli
├── services/
│   ├── auth_service.dart        # Firebase Auth + Google Sign-In
│   ├── order_service.dart       # Sipariş CRUD + real-time streams
│   ├── menu_service.dart        # Menü/yemek CRUD + Firestore
│   ├── cart_service.dart        # Sepet state yönetimi
│   ├── review_service.dart      # Yorum sistemi
│   ├── coupon_service.dart      # Kupon doğrulama ve yönetimi
│   ├── language_service.dart    # TR/EN dil servisi
│   ├── theme_service.dart       # Açık/koyu tema
│   ├── notification_service.dart # FCM push notifications
│   └── stock_prediction_service.dart # Stok tahmin servisi
├── screens/
│   ├── login_screen.dart        # Giriş ekranı
│   ├── signup_screen.dart       # Kayıt + admin kodu doğrulama
│   ├── home_screen.dart         # Ana ekran (menü, arama, kategoriler)
│   ├── meal_detail_screen.dart  # Yemek detayı + slide-to-add sepet
│   ├── cart_screen.dart         # Sepet + kupon + çapraz satış
│   ├── order_screen.dart        # Sipariş onaylama ekranı
│   ├── order_success_screen.dart # Başarılı sipariş + confetti
│   ├── order_tracking_screen.dart# Sipariş takip (real-time Firestore)
│   ├── profile_screen.dart      # Profil + sipariş geçmişi
│   ├── admin_screen.dart        # Admin dashboard
│   ├── coupon_screen.dart       # Kupon sayfası
│   └── ...
└── widgets/
    ├── review_dialog.dart       # Değerlendirme dialog
    └── ...
```

### State Management
Provider paketi ile `ChangeNotifier` tabanlı state yönetimi:
- `AuthService` → Kimlik doğrulama durumu
- `MenuService` → Menü ve yemekler
- `CartService` → Sepet içeriği
- `OrderService` → Sipariş durumu (kullanıcı + admin)
- `ReviewService` → Yorumlar
- `CouponService` → Kuponlar
- `ThemeService` → Tema
- `LanguageService` → Dil

---

## 🔧 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio veya VS Code
- Firebase projesi (Firestore, Auth, Storage, Messaging)

### 1. Bağımlılıkları Yükle
```bash
flutter pub get
```

### 2. Firebase Yapılandırması
`google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını ilgili dizinlere yerleştirin.

### 3. `.env` Dosyasını Yapılandır
Proje kökünde `.env` dosyası oluşturun:
```env
ADMIN_SECRET_CODE=your_admin_code_here
```

### 4. Uygulamayı Çalıştır
```bash
flutter run
```

### APK Build
```bash
flutter build apk --release
```

---

## 🔑 Firebase Yapısı (Firestore Collections)

| Collection | Açıklama |
|------------|----------|
| `users` | Kullanıcı profilleri ve rol bilgisi |
| `meals` | Menüdeki yemekler (ad, fiyat, besin değerleri, stok) |
| `orders` | Siparişler (items, status, userId, totalPrice) |
| `reviews` | Yemek değerlendirmeleri (rating, comment, userId, mealId) |
| `coupons` | İndirim kuponları (code, discountAmount/Percentage, expiryDate) |

### Sipariş Durumları (`OrderStatus` Enum)
```
pending → preparing → ready → completed
                   ↘ cancelled
```

---

## 👨‍💼 Admin Rolü

Admin rolü iki yolla belirlenir:
1. **Kayıt sırasında**: Özel admin kodu (`.env`'deki `ADMIN_SECRET_CODE`) girilirse kullanıcıya admin rolü atanır ve `users` koleksiyonuna `isAdmin: true` yazılır.
2. **Firestore doğrulama**: `AuthService` her giriş/kayıt sonrası Firestore'dan `users/{uid}.isAdmin` alanını kontrol eder.

---

## 📱 Kullanıcı Akışı

```
Uygulama Açılışı
      ↓
Giriş / Kayıt (Email veya Google)
      ↓
Ana Ekran (Menü Listesi)
      ↓
Yemek Detayı → Sepete Ekle (Slide-to-Add)
      ↓
Sepet → Kupon → Siparişi Onayla
      ↓
Sipariş Başarılı (Konfeti + Sipariş No)
      ↓
Sipariş Takibi (Real-time: Bekliyor → Hazırlanıyor → Hazır → Tamamlandı)
      ↓
Değerlendirme (Tamamlanan siparişler için)
```

---

## 🎫 Test Kuponları

| Kod | İndirim | Açıklama |
|-----|---------|----------|
| `FIS10` | %10 | Tüm ürünlerde |
| `WELCOME25` | ₺25 sabit | Hoşgeldin kuponu |

> Kuponları admin panelinden oluşturabilir veya `CouponService.seedInitialCoupons()` ile Firestore'a yükleyebilirsiniz.

---

## 🛠️ Bilinen Sorunlar ve Notlar

### ✅ Düzgün Çalışanlar
- 🔐 **E-posta/şifre kayıt ve giriş & Google Sign-In**
- 🍽️ **Menü listeleme ve kategori filtreleri** (vegan, glütensiz ve kategoriler kusursuz ve anlık olarak çalışır)
- 🛒 **Sepet yönetimi** (ürün ekleme/çıkarma, miktar güncelleme ve kupon kodları)
- 📝 **İndirim Kuponları** (yüzde ve sabit tutarlı kuponların doğrulanması)
- 📦 **Sipariş oluşturma ve Firestore entegrasyonu**
- 📍 **Real-time sipariş takibi** (Firestore StreamBuilder ile anlık güncellemeler)
- 👨‍💼 **Admin panelinde sipariş durum güncellemeleri**
- 💬 **Yorum ve değerlendirme sistemi** (yemek detay sayfasındaki puan ortalaması gerçek zamanlı ReviewService verilerine bağlıdır)
- 👤 **Profil sayfası, sipariş geçmişi ve karanlık mod**
- ⏰ **Sipariş sırası ve tahmini bekleme süresi hesaplayıcı**
- 🤖 **İKAS Fis Akıllı Asistanı (AI Chatbot):**
  - Akıllı Toy Robot FAB butonu ve modern glassmorphic chat overlay arayüzü.
  - Öncelikli arama motoru (Tam isim > Tam kelime > Baş harf kelime > Alt kelime eşleşmesi) ile kusursuz ürün arama.
  - Türkçe/İngilizce otomatik normalizasyon ve dil desteği.
  - Kararsız kullanıcılar için adım adım kalori/diyet odaklı yemek tavsiyesi ve sepet özetleri.
  - Önerilen yemeklerin yanındaki inline butonlar ile doğrudan chat içinden sepete ürün ekleme.
  - **Saçma/Nonsense Filtresi:** Rastgele harf mosh'ları (gibberish) ve anlamsız soruları analiz ederek kapsam dışı sorgularda profesyonel fallback cevabı verir.
- 📋 **Anasayfa Günün Menüsü Akıllı Sıralama:**
  - Günün Menüsü aktifken anasayfadaki "Tüm Menü" listesinde veritabanındaki tüm yemekler listelenmeye devam eder.
  - Menüdeki yemekler, **Günün Menüsü'ne dahil edilen yemekler listenin en başında (ilk sırada)** olacak şekilde öncelikli sıralanır.
  - Günün menüsünde olmayan diğer yemekler hafif soluk gösterilir, sepete ekleme butonları kilitlenir ve üzerlerinde kırmızı "Bugün Servis Edilmiyor" rozeti yer alır. Bu sayede mükerrer gösterim önlenir ve kullanıcı sipariş kurallarına uymaya zorlanır.

### ⚠️ Dikkat Edilmesi Gerekenler
- **SMS / Email paylaşımı:** `_shareMeal()` içindeki SMS ve Email butonları sadece modal kapatır, gerçek paylaşım API'sine bağlı değildir.
- **iOS push notification:** `firebase_messaging` paketi Android'de test edilmiştir; iOS için Apple geliştirici sertifikaları (APNs) gerekir.
- **Destek E-postası:** Uygulama genelinde ve admin panellerinde tüm yardım/destek ve stok bildirim mailleri resmi **ikasfoodnotification@gmail.com** adresine yönlendirilmiştir.

### 🔴 Kritik Kontroller
- Firebase `google-services.json` eksikse uygulama mock modda çalışabilir.
- `.env` dosyasında `ADMIN_SECRET_CODE` tanımlı değilse admin kaydı gerçekleştirilemez.
- Firestore Security Rules izinleri veritabanı okumaları için açık olmalıdır.

---

## 📦 Kullanılan Paketler

| Paket | Amaç |
|-------|------|
| `firebase_core` | Firebase başlatma |
| `firebase_auth` | Kimlik doğrulama |
| `cloud_firestore` | Gerçek zamanlı veritabanı |
| `firebase_storage` | Resim yükleme |
| `firebase_messaging` | Push bildirimler |
| `google_sign_in` | Google ile giriş |
| `provider` | State yönetimi |
| `google_fonts` | Poppins yazı tipi |
| `flutter_animate` | Animasyonlar |
| `confetti` | Sipariş başarı efekti |
| `shimmer` | Yükleme efektleri |
| `cached_network_image` | Resim önbellekleme |
| `image_picker` | Kamera/galeri erişimi |
| `shared_preferences` | Yerel depolama |
| `flutter_dotenv` | `.env` dosyası okuma |
| `app_links` | Deep link yönetimi |
| `lottie` | JSON animasyonlar |

---

## 🏠 Landing Page

`landing_page/` dizininde HTML tabanlı bir tanıtım sayfası bulunmaktadır. APK indirme bağlantısı (`app-release.apk`) buradan sunulabilir.

---

## 👥 Geliştirici

**Proje:** iKAS Fis  
**Platform:** Flutter (Android & iOS)  
**Backend:** Firebase (Firestore + Auth + Storage + Messaging)  
**Destek E-posta:** ikasfoodnotification@gmail.com  
**Versiyon:** 1.0.0+1

---

*© 2024 iKAS Fis — Tüm hakları saklıdır.*
