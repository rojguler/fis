# 🔥 Firebase Hızlı Çözüm

## Sorun: google-services.json dosyası eksik

### ⚡ Hızlı Çözüm (5 dakika):

1. **Firebase Console'a git**: https://console.firebase.google.com/
2. **Proje oluştur** veya mevcut projeyi seç
3. **Android uygulaması ekle**:
   - ⚙️ > Project settings > Your apps > Add app > Android
   - Package name: `com.example.ikas_fis`
   - Register app
4. **google-services.json dosyasını indir**
5. **Dosyayı kopyala**: `android/app/google-services.json` klasörüne

### 📁 Dosya Konumu:
```
ikas/
└── android/
    └── app/
        └── google-services.json  ← Buraya kopyala
```

### ✅ Sonra tekrar dene:
```bash
flutter run
```

---

## 🚫 Geçici Çözüm (Firebase olmadan test)

Eğer şimdilik Firebase olmadan test etmek isterseniz, Google Services plugin'ini geçici olarak devre dışı bırakabilirsiniz. Ama bu durumda Firebase özellikleri çalışmayacak.

