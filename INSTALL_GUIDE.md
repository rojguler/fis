# 📱 Telefona Yükleme Rehberi

## Android Telefona Yükleme

### Yöntem 1: USB ile Yükleme (Önerilen)

#### Adım 1: Geliştirici Seçeneklerini Aç
1. Telefonunuzda **Ayarlar** > **Telefon Hakkında** (veya **Cihaz Bilgisi**)
2. **Yapı Numarası**'na 7 kez tıklayın
3. "Geliştirici oldunuz!" mesajı görünecek

#### Adım 2: USB Hata Ayıklamayı Aç
1. **Ayarlar** > **Geliştirici Seçenekleri**
2. **USB Hata Ayıklama**'yı açın
3. Telefonu USB ile bilgisayara bağlayın
4. Telefonda "USB hata ayıklamaya izin ver?" sorusuna **İzin Ver** deyin

#### Adım 3: Flutter ile Yükle
```bash
# Bağlı cihazları kontrol et
flutter devices

# Uygulamayı çalıştır (otomatik yüklenir)
flutter run

# Veya APK oluştur
flutter build apk --debug
```

APK dosyası: `build/app/outputs/flutter-apk/app-debug.apk`

---

### Yöntem 2: APK Dosyası ile Yükleme

#### Adım 1: APK Oluştur
```bash
# Debug APK (test için)
flutter build apk --debug

# Release APK (yayın için)
flutter build apk --release
```

APK dosyası şu konumda olacak:
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

#### Adım 2: APK'yı Telefona Aktar
1. APK dosyasını USB ile telefona kopyalayın
2. Veya Google Drive/Dropbox ile paylaşın
3. Veya email ile gönderin

#### Adım 3: Telefonda Yükle
1. Telefonda **Dosya Yöneticisi**'ni açın
2. APK dosyasını bulun
3. APK'ya tıklayın
4. "Bilinmeyen kaynaklardan yükleme" izni verin
5. **Yükle** butonuna tıklayın

---

### Yöntem 3: WiFi ile Yükleme (Wireless Debugging)

#### Android 11+ için:
1. Telefonda **Geliştirici Seçenekleri** > **Kablosuz Hata Ayıklama**'yı açın
2. IP adresini ve port numarasını not edin
3. Bilgisayarda:
```bash
adb connect TELEFON_IP_ADRESI:PORT
flutter run
```

---

## iOS Telefona Yükleme (Mac Gerekli)

### Gereksinimler:
- Mac bilgisayar
- Xcode yüklü
- Apple Developer hesabı (ücretsiz)

### Adımlar:
```bash
# iOS için build
flutter build ios

# Xcode'da aç
open ios/Runner.xcworkspace

# Xcode'da:
# 1. Signing & Capabilities'de Apple ID ekle
# 2. Cihazı seç
# 3. Run butonuna tıkla
```

---

## Hızlı Test Komutları

```bash
# Bağlı cihazları listele
flutter devices

# Uygulamayı çalıştır (otomatik yüklenir)
flutter run

# Hot reload için 'r' tuşuna bas
# Hot restart için 'R' tuşuna bas
# Çıkmak için 'q' tuşuna bas

# APK boyutunu kontrol et
flutter build apk --analyze-size
```

---

## Sorun Giderme

### "No devices found" hatası:
```bash
# ADB'yi kontrol et
adb devices

# ADB'yi yeniden başlat
adb kill-server
adb start-server
```

### "USB hata ayıklama" görünmüyor:
- Telefonu USB ile bağlayın
- USB modunu "Dosya Aktarımı" (MTP) olarak seçin
- Farklı bir USB kablosu deneyin

### APK yüklenmiyor:
- **Ayarlar** > **Güvenlik** > **Bilinmeyen Kaynaklar**'ı açın
- APK dosyasının bozuk olmadığını kontrol edin
- Yeterli depolama alanı olduğundan emin olun

---

## Firebase Yapılandırması

Telefona yüklemeden önce Firebase'i yapılandırdığınızdan emin olun:
1. `google-services.json` dosyası `android/app/` klasöründe olmalı
2. `lib/firebase_options.dart` dosyasındaki değerler güncellenmeli

Detaylar için `FIREBASE_AUTO_SETUP.md` dosyasına bakın.

---

## Öneriler

- **Test için**: Debug APK kullanın (daha hızlı)
- **Yayın için**: Release APK kullanın (daha küçük, optimize)
- **Geliştirme sırasında**: `flutter run` kullanın (hot reload için)

