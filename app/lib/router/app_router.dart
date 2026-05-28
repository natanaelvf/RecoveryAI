
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/supabase_config.dart';
import '../providers/contractor_provider.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/leads_screen.dart';
import '../screens/lead_detail_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../widgets/bottom_nav_shell.dart';

/// Global navigator key — used by NotificationService for deep linking
/// from push notification taps (no BuildContext needed).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges the Supabase auth state stream + onboarding completion
/// into a single [ChangeNotifier] that GoRouter can listen to.
/// Only fires when isAuthenticated or isComplete actually change — NOT on every
/// keystroke or step change within onboarding.
class _RouterRefreshNotifier extends ChangeNotifier {
  bool _wasAuthenticated = false;
  bool _wasOnboardingComplete = false;
  late final StreamSubscription<sb.AuthState> _authSub;

  _RouterRefreshNotifier() {
    // Seed from the current session.
    _wasAuthenticated = supabase.auth.currentSession != null;

    // React to Supabase auth changes.
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      final isNowAuthenticated = data.session != null;
      if (isNowAuthenticated != _wasAuthenticated) {
        _wasAuthenticated = isNowAuthenticated;
        notifyListeners();
      }
    });
  }

  /// Called by the contractor provider listener when onboarding completion changes.
  void updateOnboarding(bool isOnboardingComplete) {
    if (isOnboardingComplete != _wasOnboardingComplete) {
      _wasOnboardingComplete = isOnboardingComplete;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier();

  // Listen to onboarding completion changes (derived from contractor data).
  ref.listen(isOnboardingCompleteProvider, (_, isComplete) {
    notifier.updateOnboarding(isComplete);
  });

  ref.onDispose(() => notifier.dispose());

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
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Check Supabase session directly — the source of truth.
      final isLoggedIn = supabase.auth.currentSession != null;

      // Read onboarding state from the contractor provider.
      final container = ProviderScope.containerOf(context);
      final hasCompletedOnboarding =
          container.read(isOnboardingCompleteProvider);

      final isLoginRoute = state.matchedLocation == '/login';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      // Not logged in → force login
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // Logged in but on login page → check onboarding
      if (isLoggedIn && isLoginRoute) {
        return hasCompletedOnboarding ? '/dashboard' : '/onboarding';
      }

      // Logged in, onboarding complete, still on onboarding → go to dashboard
      if (isLoggedIn && hasCompletedOnboarding && isOnboardingRoute) {
        return '/dashboard';
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
