import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      const androidChannel = AndroidNotificationChannel(
        'default_channel',
        'RobotInn Notifications',
        description: 'Important notifications regarding your orders and messages.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: initSettingsAndroid);
      await _localNotifications.initialize(initSettings);

      final token = await _messaging.getToken();
      if (token != null) {
        await StorageService.storeData(AppConstants.fcmToken, token);
        await ApiService.registerFCMToken(token);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

 
      _messaging.onTokenRefresh.listen((newToken) async {
        await StorageService.storeData(AppConstants.fcmToken, newToken);
        await ApiService.registerFCMToken(newToken);
      });
    } catch (_) {}
  }
}
