import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request Permission (iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Get the token (for debugging/targeted notifications)
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // 3. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification?.title}');
        _showForegroundNotification(message);
      }
    });

    // 4. Handle messages that open the app from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked!');
      // Navigate to orders or specific screen if needed
    });
  }

  static void _showForegroundNotification(RemoteMessage message) {
    final context = globalMessengerKey.currentContext;
    if (context != null) {
      final lang = Provider.of<LanguageService>(context, listen: false);
      
      globalMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.notification?.body ?? ''),
            ],
          ),
          backgroundColor: IKASColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(20),
          action: SnackBarAction(
            label: lang.isTurkish ? 'Kapat' : 'Close',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Saves the current user's FCM token to Firestore for targeted notifications
  static Future<void> saveTokenToFirestore(String userId) async {
    if (userId.isEmpty) return;
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token saved for user $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
