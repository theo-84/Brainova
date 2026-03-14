import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/service/notification_service.dart';
import 'core/service/background_notification_service.dart';
import 'core/service/daily_reset_service.dart';

import 'features/gamification/domain/badge_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize App Check (Debug mode only)
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    } catch (e) {
      debugPrint('App Check initialization failed (non-fatal): $e');
    }

    await NotificationService().init();
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const ProviderScope(child: BrainovaApp()));
}

class BrainovaApp extends ConsumerWidget {
  const BrainovaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start periodic checks and Badge Service
    Future.microtask(() async {
      await ref.read(backgroundNotificationServiceProvider).initializeService();
      ref.read(badgeServiceProvider); // Wake up the badge service
      // Check and reset daily counters if the calendar day has changed
      await ref.read(dailyResetServiceProvider).checkAndResetIfNeeded();
    });

    return MaterialApp.router(
      title: 'Brainova',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
