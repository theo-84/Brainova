import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init({bool isBackground = false}) async {
    print(
        'DEBUG: Initializing NotificationService for platform: $defaultTargetPlatform (isBackground: $isBackground)');
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isDarwin = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (!isAndroid && !isDarwin) {
      print(
          'DEBUG: NotificationService init skipped - Platform $defaultTargetPlatform not natively supported by this plugin.');
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    print('DEBUG: Calling _notifications.initialize...');
    await _notifications.initialize(settings);
    print('DEBUG: _notifications.initialize completed.');

    if (!isBackground) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        print('DEBUG: Requesting Android notification permissions...');
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (!status.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('Error requesting battery optimization exemption: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'brainova_channel',
      'Brainova Alerts',
      channelDescription: 'Notifications for your brain health and habits',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      fullScreenIntent: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        return;
      }
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }
}
