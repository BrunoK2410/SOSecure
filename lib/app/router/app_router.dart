import 'package:go_router/go_router.dart';

import '../../ui/auth/auth_view_model.dart';
import '../../ui/auth/login/login_screen.dart';
import '../../ui/auth/register/register_screen.dart';
import '../../ui/contacts/contacts_screen.dart';
import '../../ui/history/history_screen.dart';
import '../../ui/home/home_screen.dart';
import '../../ui/map/map_screen.dart';
import '../../ui/profile/account_info_screen.dart';
import '../../ui/profile/profile_screen.dart';
import '../../ui/profile/safety_prefs_screen.dart';
import '../../ui/shared/main_shell.dart';
import '../../ui/alerts/alert_detail_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final isInitialized = authViewModel.isInitialized;
        final isLoggedIn = authViewModel.isLoggedIn;
        final isAuthRoute =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!isInitialized) {
          // While initializing, return null to show the native splash background
          return null;
        }


        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        if (isLoggedIn && isAuthRoute) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(
              path: '/contacts',
              builder: (context, state) => const ContactsScreen(),
            ),
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'account-info',
                  builder: (context, state) => const AccountInfoScreen(),
                ),
                GoRoute(
                  path: 'safety-prefs',
                  builder: (context, state) => const SafetyPrefsScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/alert-detail/:alertId',
          builder: (context, state) => AlertDetailScreen(
            alertId: state.pathParameters['alertId']!,
          ),
        ),
      ],
    );
  }
}
