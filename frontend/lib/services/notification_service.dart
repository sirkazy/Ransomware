import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification clicked: ${details.payload}');
      },
    );

    _initialized = true;
    debugPrint('NotificationService: initialized successfully');

    // Request permissions on startup
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final granted = await androidImplementation.requestNotificationsPermission();
          debugPrint('NotificationService: Android permission request result: $granted');
        } else {
          debugPrint('NotificationService: Android implementation was null');
        }
      } else if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation != null) {
          final granted = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('NotificationService: iOS permission request result: $granted');
        }
      }
    } catch (e) {
      debugPrint('Error requesting notifications permissions: $e');
    }
  }

  Future<void> showThreatNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      debugPrint('NotificationService: showThreatNotification called: $title - $body');
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'ransomware_alerts',
        'Ransomware Guardian Alerts',
        channelDescription: 'Real-time notifications for ransomware threats',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        icon: 'ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails darwinNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('NotificationService: show call completed');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}
