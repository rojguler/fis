const functions = require('firebase-functions');
const admin = require('firebase-admin');
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
