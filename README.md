# iKAS Fis - Akıllı Yemek & Sipariş Sistemi 🍽️

iKAS Fis, kullanıcıların günlük menüleri takip edebildiği, kalori ve besin değerlerini inceleyebildiği ve saniyeler içinde sipariş verip gerçek zamanlı takip edebildiği modern bir Flutter uygulamasıdır.

## 🚀 Öne Çıkan Özellikler

- **Modern UI/UX:** Dark mode destekli, Google Fonts (Poppins) ile güçlendirilmiş premium tasarım.
- **Gerçek Zamanlı Takip:** Sipariş durumunu (Hazırlanıyor, Hazır, Tamamlandı) anlık olarak takip edin.
- **E-Posta Bildirimleri:** Menü güncellemeleri ve sipariş durum değişikliklerinde otomatik e-posta bildirimleri (Brevo API).
- **Stok Yönetimi:** Admin paneli üzerinden anlık stok takibi ve otomatik stok düşümü/iadesi.
- **Besin Analizi:** Yemeklerin kalori, protein ve alerjen bilgilerini görüntüleme.
- **Admin Paneli:** Ürün ekleme, düzenleme ve sipariş yönetimi için kapsamlı kontrol merkezi.

## 🛠️ Teknoloji Yığını

- **Frontend:** Flutter & Dart
- **State Management:** Provider
- **Backend:** Firebase (Firestore, Auth)
- **Email:** Brevo REST API
- **Local Env:** Flutter Dotenv

## 📦 Kurulum

1.  Repoyu klonlayın: `git clone https://github.com/kullanici/ikas_fis.git`
2.  Bağımlılıkları yükleyin: `flutter pub get`
3.  `.env` dosyasını oluşturun ve API anahtarlarınızı ekleyin:
    ```env
    BREVO_API_KEY=your_api_key_here
    SENDER_EMAIL=your_sender_email@example.com
    SENDER_NAME=iKAS_Fis
    ```
4.  Uygulamayı çalıştırın: `flutter run`

## 🔐 Güvenlik

- API anahtarları `.env` dosyası ile korunmaktadır.
- Admin yetkileri Firebase Auth ve Firestore rolleri ile yönetilmektedir.
- Kritik işlemler (stok düşümü vb.) Firestore Transaction ile güvence altına alınmıştır.

---
*Bu proje iKAS için özel olarak geliştirilmiştir.*
