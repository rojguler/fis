# 📱 Telefona Yükleme - Hızlı Rehber

## ⚡ En Kolay Yöntem: USB ile Yükleme

### 1️⃣ Telefonda Ayarlar (İlk Kez)

1. **Ayarlar** > **Telefon Hakkında** (veya **Cihaz Bilgisi**)
2. **Yapı Numarası**'na **7 kez** tıklayın
3. "Geliştirici oldunuz!" mesajı görünecek

4. **Ayarlar** > **Geliştirici Seçenekleri**
5. **USB Hata Ayıklama**'yı **AÇIN**

### 2️⃣ Telefonu Bağla

1. Telefonu USB kablosu ile bilgisayara bağlayın
2. Telefonda "USB hata ayıklamaya izin ver?" sorusuna **İzin Ver** deyin
3. "Bu bilgisayara her zaman izin ver" seçeneğini işaretleyin

### 3️⃣ Bilgisayarda Yükle

Terminal'de şu komutu çalıştırın:

```bash
flutter run
```

Flutter otomatik olarak:
- Telefonu bulacak
- Uygulamayı yükleyecek
- Çalıştıracak

---

## 📦 APK Dosyası Oluşturma (Manuel Yükleme)

Eğer USB ile bağlayamıyorsanız, APK dosyası oluşturup manuel yükleyebilirsiniz:

### 1. APK Oluştur

```bash
flutter build apk --debug
```

APK dosyası şu konumda oluşacak:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### 2. APK'yı Telefona Aktar

- USB ile kopyalayın
- Veya Google Drive/Dropbox ile paylaşın
- Veya email ile gönderin

### 3. Telefonda Yükle

1. **Dosya Yöneticisi**'ni açın
2. APK dosyasını bulun
3. APK'ya tıklayın
4. "Bilinmeyen kaynaklardan yükleme" izni verin
5. **Yükle** butonuna tıklayın

---

## 🔍 Cihaz Kontrolü

### Bağlı cihazları görmek için:
```bash
flutter devices
```

### Eğer cihaz görünmüyorsa:
1. USB kablosunu değiştirin
2. USB modunu "Dosya Aktarımı" (MTP) yapın
3. Telefonu yeniden bağlayın
4. Geliştirici seçeneklerini kontrol edin

---

## 🚀 Hızlı Komutlar

```bash
# Uygulamayı çalıştır (otomatik yüklenir)
flutter run

# Sadece APK oluştur
flutter build apk --debug

# Release APK (daha küçük, optimize)
flutter build apk --release
```

---

## ⚠️ Önemli Notlar

1. **Firebase Yapılandırması**: Telefona yüklemeden önce Firebase'i yapılandırdığınızdan emin olun
   - `google-services.json` dosyası `android/app/` klasöründe olmalı
   - `lib/firebase_options.dart` dosyasındaki değerler güncellenmeli

2. **İlk Yükleme**: İlk yükleme biraz uzun sürebilir (1-2 dakika)

3. **Hot Reload**: `flutter run` ile çalıştırırsanız, kod değişikliklerini anında görebilirsiniz
   - Terminal'de `r` tuşuna basın = Hot reload
   - Terminal'de `R` tuşuna basın = Hot restart
   - Terminal'de `q` tuşuna basın = Çıkış

---

## 🆘 Sorun Giderme

### "No devices found" hatası:
- USB hata ayıklamayı kontrol edin
- Farklı bir USB kablosu deneyin
- Telefonu yeniden bağlayın

### "Device not authorized" hatası:
- Telefonda "USB hata ayıklamaya izin ver" diyalogunu onaylayın
- "Bu bilgisayara her zaman izin ver" seçeneğini işaretleyin

### APK yüklenmiyor:
- **Ayarlar** > **Güvenlik** > **Bilinmeyen Kaynaklar**'ı açın
- Yeterli depolama alanı olduğundan emin olun

