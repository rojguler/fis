const admin = require('firebase-admin');
const fs = require('fs');

// Service Account dosyasının varlığını kontrol et
if (!fs.existsSync('./serviceAccountKey.json')) {
    console.error("HATA: serviceAccountKey.json dosyası bulunamadı!");
    console.error("Lütfen Firebase konsolundan dosyayı indirip bu klasöre koyun.");
    process.exit(1);
}

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

console.log("-------------------------------------------------");
console.log("✅ Lokal Bildirim Sunucusu Çalışıyor...");
console.log("Sipariş güncellemeleri dinleniyor. Kapatmak için CTRL+C yapın.");
console.log("-------------------------------------------------");

// Daha önce işlenmiş güncellemeleri tekrar göndermemek için ufak bir hafıza
const processedUpdates = new Set();

db.collection('orders').onSnapshot((snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
        // Sadece güncellenen siparişleri yakala
        if (change.type === 'modified') {
            const newValue = change.doc.data();
            const orderId = change.doc.id;
            const status = newValue.status;
            
            // Aynı güncellemeyi iki kez atmamak için kontrol
            const updateKey = `${orderId}_${status}`;
            if (processedUpdates.has(updateKey)) return;
            processedUpdates.add(updateKey);

            const userId = newValue.userId;
            const orderNumber = newValue.orderNumber || orderId.substring(0, 5);

            // Kullanıcının FCM Token'ını al
            const userDoc = await db.collection('users').doc(userId).get();
            if (!userDoc.exists || !userDoc.data().fcmToken) {
                console.log(`❌ Kullanıcı (${userId}) bulunamadı veya Token'ı yok.`);
                return;
            }

            const fcmToken = userDoc.data().fcmToken;

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
                    orderId: orderId,
                    click_action: 'FLUTTER_NOTIFICATION_CLICK',
                }
            };

            try {
                await admin.messaging().send(message);
                console.log(`✅ Bildirim gönderildi: #${orderNumber} -> ${status}`);
            } catch (error) {
                console.error('❌ Bildirim gönderme hatası:', error.message);
            }
        }
    });
}, (error) => {
    console.error("Dinleme hatası:", error);
});
