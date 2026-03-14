import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:brainova/features/tracking/data/activity_repository.dart';
import 'package:brainova/features/auth/data/auth_providers.dart';

class PermissionCheckerScreen extends ConsumerStatefulWidget {
  const PermissionCheckerScreen({super.key});

  @override
  ConsumerState<PermissionCheckerScreen> createState() =>
      _PermissionCheckerScreenState();
}

class _PermissionCheckerScreenState
    extends ConsumerState<PermissionCheckerScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    // Skip on non-Android platforms
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) {
      // Logic handled via listener for auth state
      return;
    }

    final repo = ref.read(activityRepositoryProvider);
    final hasPermission = await repo.checkRealDataAvailability();

    if (!mounted) return;

    if (!hasPermission) {
      setState(() => _isChecking = false);
    }
    // If hasPermission, the ref.listen in build will handle navigation
    // once auth state is resolved.
  }

  void _navigateToNext(UserModel? user) {
    if (!mounted) return;
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/intro');
    }
  }

  Future<void> _openSettings() async {
    final repo = ref.read(activityRepositoryProvider);

    setState(() => _isChecking = true);

    await repo.openUsageSettings();

    // Wait a bit for user to return
    await Future.delayed(const Duration(seconds: 2));

    await _checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    // Reactive listener for auth state to handle redirects robustly
    ref.listen<AsyncValue<UserModel?>>(authStateProvider, (previous, next) {
      next.whenData((user) async {
        final isAndroid =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

        if (!isAndroid) {
          _navigateToNext(user);
          return;
        }

        final repo = ref.read(activityRepositoryProvider);
        final hasPermission = await repo.checkRealDataAvailability();

        if (hasPermission && mounted) {
          _navigateToNext(user);
        }
      });
    });

    if (_isChecking) {
      return _buildSplashScreen();
    }

    return _buildPermissionScreen();
  }

  Widget _buildSplashScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 80),
            const SizedBox(height: 32),
            const Text(
              'Enable Usage Access',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Brainova needs usage access permission to track screen time and calculate your Brain Rot score.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _openSettings,
              child: const Text('Open Settings'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
