import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Request permission (Crucial for iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Advanced Local Notifications Setup (Android & iOS)
    const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSet = InitializationSettings(android: initAndroid, iOS: initIOS);
    await _localNotif.initialize(
      initSet,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          debugPrint("User tapped a local notification! Payload: ${response.payload}");
          // Add custom routing logic here based on your payload
        }
      },
    );

    // Create High Importance Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'ashall_alerts_channel', // id
      'Ashall System Alerts', // title
      description: 'هذه القناة مخصصة للإشعارات الهامة والعمليات المباشرة', // description
      importance: Importance.max,
    );

    await _localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      if (message.data.isNotEmpty) {
        debugPrint("Message data payload: ${message.data}");
      }
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, 
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              enableVibration: true,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle Background/Terminated Messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("User tapped a notification from background! Data: ${message.data}");
    });

    // Handle App completely terminated and opened by clicking a notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("User opened the app from a terminated state via notification! Data: ${initialMessage.data}");
    }

    // Subscribe to a general topic (for global announcements)
    await _fcm.subscribeToTopic('all_users').catchError((e) => debugPrint("Topic subscription error: $e"));
    debugPrint("Subscribed to global 'all_users' topic");
    
    // Listen to token refresh and update Firestore if possible
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token Refreshed: $newToken");
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': newToken});
        } catch (e) {
          debugPrint("Token sync on refresh failed: $e");
        }
      }
    });
  }

  // Topics functions
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    debugPrint("Subscribed to topic: $topic");
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    debugPrint("Unsubscribed from topic: $topic");
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  // Helper to show a local notification immediately from the app itself
  Future<void> showLocalNotification({required String title, required String body, Map<String, dynamic>? payload}) async {
    await _localNotif.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'ashall_alerts_channel', 'Ashall System Alerts',
          importance: Importance.max, priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }
}
