import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings: initSettings);

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: message.notification!.title,
      body: message.notification!.body,
      notificationDetails: details,
    );
  }

  static Future<void> updateToken(String userId) async {
    String? token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "fcmToken": token,
      });
    }
  }

  // Note: For real push notifications to work from app-to-app without a backend,
  // we would need to use FCM Legacy API (not recommended) or FCM v1 with a service account.
  // For now, we setup the receiver side logic.
}
