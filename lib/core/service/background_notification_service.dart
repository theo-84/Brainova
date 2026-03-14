import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../../features/tracking/data/activity_model.dart';

final backgroundNotificationServiceProvider =
    Provider<BackgroundNotificationService>((ref) {
  return BackgroundNotificationService();
});

class BackgroundNotificationService {
  BackgroundNotificationService();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'brainova_channel',
        initialNotificationTitle: 'Brainova Tracking',
        initialNotificationContent: 'Monitoring your digital habits',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  void start() {
    FlutterBackgroundService().startService();
  }

  void stop() {
    FlutterBackgroundService().invoke("stopService");
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize Firebase inside the background isolate
  try {
    print('DEBUG BG: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('DEBUG BG: Firebase initialized');
  } catch (e) {
    print('DEBUG BG: Firebase init error: $e');
    return; // Can't proceed without Firebase
  }

  // Initialize notifications
  try {
    await NotificationService().init(isBackground: true);
    print('DEBUG BG: Notifications initialized');
  } catch (e) {
    print('DEBUG BG: Notification init error: $e');
    return;
  }

  // Heartbeat: confirm background service is alive
  try {
    await NotificationService().showNotification(
      title: "Brainova is Active",
      body: "Background habit monitoring started.",
    );
    print('DEBUG BG: Heartbeat sent');
  } catch (e) {
    print('DEBUG BG: Heartbeat error: $e');
  }

  // Poll every 2 minutes using only Firestore (no MethodChannel needed)
  Timer.periodic(const Duration(minutes: 2), (timer) async {
    print('DEBUG BG: Timer fired');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('DEBUG BG: No logged-in user, skipping');
      return;
    }

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Brainova Active",
          content:
              "Monitoring habits... ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
        );
      }
    }

    try {
      final score = await _computeScoreFromFirestore(user.uid);
      print('DEBUG BG: Score = $score');

      if (score >= 60) {
        final isHighDanger = score >= 80;
        await NotificationService().showNotification(
          title: isHighDanger
              ? "⚠️ High Stimulation Detected"
              : "⚠️ Stimulation Caution",
          body: isHighDanger
              ? "Your digital habits may be affecting focus. Take a brain break!"
              : "You are leaning toward heavy stimulation. Consider a reset.",
        );
        print('DEBUG BG: Alert sent for score $score');
      }
    } catch (e) {
      print('DEBUG BG: Score computation error: $e');
    }
  });
}

/// Computes a stimulation score (0–100) purely from Firestore data.
/// This avoids MethodChannel which is unavailable in background isolates.
Future<int> _computeScoreFromFirestore(String uid) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final since = DateTime(now.year, now.month, now.day); // midnight today

  final snapshot = await firestore
      .collection('activities')
      .where('uid', isEqualTo: uid)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
      .get();

  final activities = snapshot.docs
      .map((doc) => ActivityLogModel.fromMap(doc.data(), doc.id))
      .toList();

  double junk = 0, social = 0, entertainment = 0, learning = 0, totalMin = 0;

  for (final a in activities) {
    final min = a.durationSeconds / 60;
    totalMin += min;
    switch (a.type) {
      case ActivityType.junk:
        junk += min;
        break;
      case ActivityType.social:
        social += min;
        break;
      case ActivityType.entertainment:
        entertainment += min;
        break;
      case ActivityType.learning:
      case ActivityType.rewire:
        learning += min;
        break;
      default:
        break;
    }
  }

  if (totalMin == 0) return 0;

  final rawScore =
      (junk * 1.2 + social * 1.0 + entertainment * 0.8) - (learning * 1.0);
  final normalized = (rawScore / totalMin) * 100;
  return normalized.clamp(0, 100).round();
}
