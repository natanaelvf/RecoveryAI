
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/lead_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../widgets/bottom_nav_shell.dart';

/// Combines auth + onboarding into a single Listenable for GoRouter.refreshListenable.
/// Only fires when isAuthenticated or isComplete actually change — NOT on every
/// keystroke or step change within onboarding.
class _RouterRefreshNotifier extends ChangeNotifier {
  bool _wasAuthenticated = false;
  bool _wasOnboardingComplete = false;

  void update(bool isAuthenticated, bool isOnboardingComplete) {
    if (isAuthenticated != _wasAuthenticated ||
        isOnboardingComplete != _wasOnboardingComplete) {
      _wasAuthenticated = isAuthenticated;
      _wasOnboardingComplete = isOnboardingComplete;
      notifyListeners();
    }
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();

  // Listen to auth and onboarding changes, but only propagate
  // when the values the redirect actually cares about change.
  ref.listen(authProvider, (_, auth) {
    final onboarding = ref.read(onboardingProvider);
    notifier.update(auth.isAuthenticated, onboarding.isComplete);
  });

  ref.listen(onboardingProvider, (_, onboarding) {
    final auth = ref.read(authProvider);
    notifier.update(auth.isAuthenticated, onboarding.isComplete);
  });

  return notifier;
});

/// App router configuration using go_router.
/// Routes: /login, /onboarding, /dashboard, /leads, /leads/:id, /settings, /profile
///
/// IMPORTANT: The GoRouter is created ONCE. Redirect re-evaluation is triggered
/// via refreshListenable when auth or onboarding completion status changes.
/// This prevents the router from being destroyed/recreated on every
/// onboarding field change (which would reset the PageView to page 0).
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_routerRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Read current state at redirect time (not at provider creation time)
      final container = ProviderScope.containerOf(context);
      final isLoggedIn = container.read(authProvider).isAuthenticated;
      final hasCompletedOnboarding = container.read(onboardingProvider).isComplete;

      final isLoginRoute = state.matchedLocation == '/login';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      // Not logged in → force login
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // Logged in but on login page → check onboarding
      if (isLoggedIn && isLoginRoute) {
        return hasCompletedOnboarding ? '/dashboard' : '/onboarding';
      }

      // Logged in, onboarding not complete, not on onboarding → force onboarding
      if (isLoggedIn && !hasCompletedOnboarding && !isOnboardingRoute) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      // Login — no bottom nav
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Onboarding — no bottom nav
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1: Leads
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leads',
                builder: (context, state) => const LeadsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return LeadDetailScreen(leadId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),

          // Tab 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
