# 🔧 Yükleme Hatası Çözümü

## ❌ Hata: `INSTALL_FAILED_USER_RESTRICTED`

Build başarılı ama telefona yüklenemedi. Bu hata telefonun güvenlik ayarlarından kaynaklanıyor.

## ✅ Çözüm Adımları:

### 1️⃣ Telefonda Ayarlar
1. **Ayarlar** > **Güvenlik** (veya **Uygulamalar**)
2. **Bilinmeyen Kaynaklardan Yükleme**'yi **AÇIN**
   - Veya **Uygulama Yükleme** > **Bilinmeyen Kaynaklardan Yükleme**'yi açın

### 2️⃣ USB Hata Ayıklama Kontrolü
1. **Ayarlar** > **Geliştirici Seçenekleri**
2. **USB Hata Ayıklama**'nın **AÇIK** olduğundan emin olun
3. **USB Yükleme** (Install via USB) seçeneğini **AÇIN** (varsa)

### 3️⃣ Telefonda İzin Ver
Yükleme sırasında telefon ekranında bir izin diyalogu çıkabilir:
- **"Bu bilgisayara her zaman izin ver"** seçeneğini işaretleyin
- **İzin Ver** butonuna tıklayın

### 4️⃣ Tekrar Dene
```bash
flutter run
```

---

## 🔄 Alternatif: APK'yı Manuel Yükle

Eğer hala çalışmazsa, APK dosyasını manuel yükleyebilirsiniz:

### 1. APK Dosyası Hazır
APK zaten oluşturuldu:
```
build\app\outputs\flutter-apk\app-debug.apk
```

### 2. Telefona Aktar
- USB ile kopyalayın
- Veya Google Drive/Dropbox ile paylaşın
- Veya email ile gönderin

### 3. Telefonda Yükle
1. **Dosya Yöneticisi**'ni açın
2. APK dosyasını bulun
3. APK'ya tıklayın
4. **Yükle** butonuna tıklayın
5. İzin verin

---

## 📱 Telefon Markasına Göre Ayarlar

### Xiaomi (M2010J19SG gibi görünüyor):
1. **Ayarlar** > **Uygulamalar** > **Özel Erişim**
2. **Bilinmeyen Kaynaklardan Yükleme**'yi açın
3. **USB Hata Ayıklama** ve **USB Yükleme**'yi açın

### Samsung:
1. **Ayarlar** > **Uygulamalar** > **Özel Erişim**
2. **Bilinmeyen Kaynaklardan Yükleme**'yi açın

### Diğer Markalar:
1. **Ayarlar** > **Güvenlik** > **Bilinmeyen Kaynaklar**'ı açın

---

## ✅ Başarılı Yükleme Sonrası

Uygulama yüklendikten sonra:
- Ana ekranda "ikas_fis" uygulamasını bulun
- Uygulamayı açın
- Login ekranı görünecek (Firebase yapılandırması yoksa bazı özellikler çalışmayabilir)

