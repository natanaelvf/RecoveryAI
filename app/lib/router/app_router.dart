
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

/// App router configuration using go_router.
/// Routes: /login, /onboarding, /dashboard, /leads, /leads/:id, /settings, /profile
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final onboarding = ref.watch(onboardingProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';
      final hasCompletedOnboarding = onboarding.isComplete;

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
