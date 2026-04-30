# Firebase Cloud Function ile Sipariş Bildirimi Kurulumu

Sipariş durumu güncellendiğinde kullanıcıya otomatik bildirim gitmesi için bir Firebase Cloud Function kullanmalıyız. Bu fonksiyon Firestore'daki `orders` koleksiyonunu izler ve bir değişiklik olduğunda ilgili kullanıcıya bildirim gönderir.

## 1. Hazırlık
Bilgisayarınızda Firebase CLI yüklü olmalıdır. Eğer yüklü değilse:
```bash
npm install -g firebase-tools
firebase login
```

## 2. Cloud Functions Başlatma
Proje ana dizininizde terminali açın:
```bash
firebase init functions
```
- Dil olarak **JavaScript** seçin.
- ESLint: **No**
- Bağımlılıkları yükle: **Yes**

## 3. Fonksiyon Kodunu Yazma
`functions/index.js` dosyasının içeriğini aşağıdaki kod ile değiştirin:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onOrderStatusUpdate = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // Eğer durum değişmediyse bir şey yapma
        if (newValue.status === previousValue.status) {
            return null;
        }

        const userId = newValue.userId;
        const status = newValue.status;
        const orderNumber = newValue.orderNumber || context.params.orderId.substring(0, 5);

        // Kullanıcının FCM Token'ını al
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (!userDoc.exists) {
            console.log('User not found:', userId);
            return null;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
            console.log('User has no FCM token:', userId);
            return null;
        }

        // Bildirim mesajını hazırla
        let title = 'Sipariş Güncellemesi';
        let body = `Siparişiniz #${orderNumber} durumu güncellendi: ${status}`;

        if (status === 'preparing') {
            body = `Siparişiniz #${orderNumber} hazırlanıyor! 👨‍🍳`;
        } else if (status === 'ready') {
            body = `Siparişiniz #${orderNumber} hazır! Afiyet olsun. 🍽️`;
        } else if (status === 'completed') {
            body = `Siparişiniz #${orderNumber} tamamlandı. Yine bekleriz!`;
        } else if (status === 'cancelled') {
            body = `Siparişiniz #${orderNumber} maalesef iptal edildi.`;
        }

        const message = {
            notification: {
                title: title,
                body: body,
            },
            token: fcmToken,
            data: {
                orderId: context.params.orderId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            }
        };

        try {
            await admin.messaging().send(message);
            console.log('Notification sent successfully to user:', userId);
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    });
```

## 4. Canlıya Alma (Deploy)
Fonksiyonu Firebase'e yüklemek için:
```bash
firebase deploy --only functions
```

## Önemli Notlar
- Firebase projenizin **Blaze (Pay-as-you-go)** planında olması gerekir (Cloud Functions için gereklidir, ancak ücretsiz kota oldukça geniştir).
- Bildirimlerin gelmesi için uygulamanın gerçek bir Android/iOS cihazda çalışıyor olması önerilir (Emülatörlerde bazen Google Play Services kaynaklı sorunlar olabilir).
