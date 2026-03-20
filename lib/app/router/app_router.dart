import 'package:go_router/go_router.dart';

import '../../ui/auth/login/login_screen.dart';
import '../../ui/auth/register/register_screen.dart';
import '../../ui/contacts/contacts_screen.dart';
import '../../ui/history/history_screen.dart';
import '../../ui/home/home_screen.dart';
import '../../ui/map/map_screen.dart';
import '../../ui/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
