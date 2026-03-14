import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/welcome_back_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/intro_slogan_screen.dart';
import '../../features/auth/presentation/brainova_start_screen.dart';
import '../../features/auth/presentation/get_started_screen.dart';
// import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/mind_reset/presentation/mind_reset_list_screen.dart';
import '../../features/mind_reset/presentation/activity_player_screen.dart';
import '../../features/mind_reset/data/mind_reset_model.dart';
import '../../features/rewire/presentation/rewire_screen.dart';
import '../../features/content_diet/presentation/content_diet_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_information_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/profile/presentation/privacy_security_screen.dart';
import '../../features/tracking/presentation/widgets/permission_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/reality_check/presentation/reality_check_screen.dart';
import '../presentation/main_wrapper.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // We can't easily check ref here since it's not a Consumer,
    // but we can use the provider if we pass it or use a global-ish access.
    // However, simplest is to let the screens handle it or use a redirect logic
    // if the app has a central auth state.
    return null;
  },
  routes: [
    // Permission check
    GoRoute(
      path: '/',
      builder: (context, state) => const PermissionCheckerScreen(),
    ),

    // Auth routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const WelcomeBackScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/intro',
      builder: (context, state) => const IntroSloganScreen(),
    ),
    GoRoute(
      path: '/get-started',
      builder: (context, state) => const GetStartedScreen(),
    ),
    GoRoute(
      path: '/brainova-start',
      builder: (context, state) => const BrainovaStartScreen(),
    ),
    /*
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailScreen(),
    ),
    */

    // Main app with bottom nav
    ShellRoute(
      builder: (context, state, child) {
        return MainWrapper(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/mind-reset',
          builder: (context, state) => const MindResetListScreen(),
        ),
        GoRoute(
          path: '/rewire',
          builder: (context, state) => const RewireScreen(),
        ),
        GoRoute(
          path: '/content-diet',
          builder: (context, state) => const ContentDietScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'personal-info',
              builder: (context, state) => const PersonalInformationScreen(),
            ),
            GoRoute(
              path: 'privacy',
              builder: (context, state) => const PrivacySecurityScreen(),
            ),
            GoRoute(
              path: 'help',
              builder: (context, state) => const HelpSupportScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/reality-check',
          builder: (context, state) => const RealityCheckScreen(),
        ),
      ],
    ),

    // Detail routes
    GoRoute(
      path: '/mind-reset/:id',
      name: 'mind-reset-player',
      builder: (context, state) {
        final activity = state.extra as MindResetActivity;
        return MindResetPlayerScreen(activity: activity);
      },
    ),
  ],
);
