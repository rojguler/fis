const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.onOrderStatusUpdate = functions.firestore
    .document('orders/{orderId}')
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        if (newValue.status === previousValue.status) {
            return null;
        }

        const userId = newValue.userId;
        const status = newValue.status;
        const orderNumber = newValue.orderNumber || context.params.orderId.substring(0, 5);

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

// 🔥 MENÜ değişince mail at
exports.onMenuUpdate = functions.firestore
    .document("menus/{menuId}") // collection yerine document path olmalı
    .onWrite(async (change, context) => {
        const newData = change.after.exists ? change.after.data() : null;
        const oldData = change.before.exists ? change.before.data() : null;

        // Eğer veri silindiyse mail atma
        if (!newData) return null;

        // Eğer değişiklik yoksa çık
        if (JSON.stringify(newData) === JSON.stringify(oldData)) {
            return null;
        }

        try {
            // 🔥 Kullanıcı maillerini users koleksiyonundan çek
            const usersSnapshot = await admin.firestore().collection("users").get();

            const bccList = [];
            usersSnapshot.forEach(doc => {
                const user = doc.data();
                // User objesinde email varsa ve bildirim izni kapalı değilse
                if (user.email && user.emailNotifications !== false) {
                    bccList.push({ email: user.email });
                }
            });

            if (bccList.length === 0) {
                console.log("Gönderilecek e-posta adresi bulunamadı.");
                return null;
            }

            // Brevo API Key var mı kontrol et (Yeni Firebase versiyonlarında .env kullanılır)
            const brevoApiKey = process.env.BREVO_API_KEY;
            if (!brevoApiKey) {
                console.warn("Brevo API key tanımlanmamış (.env dosyasında yok)! Mail gönderimi atlandı.");
                return null;
            }

            // 🔥 Mail içeriği ve API isteği (Gizlilik için BCC kullanılır, To'da kendi adresiniz olur)
            const senderEmail = process.env.SENDER_EMAIL || "noreply@fisapp.com"; 
            const senderName = "Fiş App";

            const data = JSON.stringify({
                sender: { name: senderName, email: senderEmail },
                to: [{ email: senderEmail, name: senderName }], // To'ya kendinizi yazın
                bcc: bccList, // Asıl alıcılar (birbirlerini görmemeleri için bcc)
                subject: "🍽️ Yeni Menü Güncellendi!",
                htmlContent: `
                    <div style="font-family: sans-serif; text-align: center; color: #333;">
                        <h2>Yeni Menü Yayında 🚀</h2>
                        <p>Bugünün yemeklerini kontrol etmeyi unutma!</p>
                        <p>Uygulamayı aç → <b>Fiş App</b></p>
                    </div>
                `
            });

            const config = {
                method: 'post',
                url: 'https://api.brevo.com/v3/smtp/email',
                headers: { 
                    'api-key': brevoApiKey, 
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                data: data
            };

            const response = await axios(config);
            console.log("Mail başarıyla gönderildi, API Yanıtı:", response.data);

            return null;
        } catch (error) {
            console.error("Mail hatası:", error);
            if (error.response && error.response.data) {
                console.error("Brevo Hata Detayı:", error.response.data);
            }
            return null;
        }
    });
