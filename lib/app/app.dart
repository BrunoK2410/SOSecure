import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/repositories/location_repository.dart';
import '../data/repositories/sos_repository.dart';
import '../data/services/firebase_auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/location_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/alert_monitoring_service.dart';
import '../data/services/audio_service.dart';
import '../data/services/storage_service.dart';
import '../ui/auth/auth_view_model.dart';
import '../ui/auth/login/login_view_model.dart';
import '../ui/auth/register/register_view_model.dart';
import '../ui/contacts/contacts_view_model.dart';
import '../ui/history/history_view_model.dart';
import '../ui/home/home_view_model.dart';
import '../ui/map/map_view_model.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SOSecureApp extends StatelessWidget {
  const SOSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseAuthService()),
        Provider(create: (_) => FirestoreService()),
        Provider(create: (_) => NotificationService()..initialize()),
        Provider(
          create: (context) => AuthRepository(
            context.read<FirebaseAuthService>(),
            context.read<FirestoreService>(),
          ),
        ),
        Provider(create: (_) => LocationService()),
        Provider(
          create: (context) =>
              LocationRepository(context.read<LocationService>()),
        ),
        Provider(
          create: (context) => ContactsRepository(
            context.read<FirestoreService>(),
          ),
        ),
        Provider(
          create: (context) => SosRepository(
            context.read<FirestoreService>(),
          ),
        ),
        Provider(create: (_) => AudioService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
            context.read<NotificationService>(),
            context.read<FirestoreService>(),
          ),
        ),
        Provider(
          create: (context) => AlertMonitoringService(
            context.read<AuthViewModel>(),
            context.read<FirestoreService>(),
            context.read<NotificationService>(),
          ),
          lazy: false, // Ensures it starts monitoring immediately
        ),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(context.read<AuthViewModel>()),
        ),
        ChangeNotifierProvider(
          create: (context) => RegisterViewModel(context.read<AuthViewModel>()),
        ),
        ChangeNotifierProvider(
          create: (context) => HomeViewModel(
            context.read<AuthViewModel>(),
            context.read<SosRepository>(),
            context.read<ContactsRepository>(),
            context.read<LocationRepository>(),
            context.read<FirestoreService>(),
            context.read<AudioService>(),
            context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ContactsViewModel(
            context.read<ContactsRepository>(),
            context.read<AuthViewModel>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              MapViewModel(context.read<LocationRepository>())..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryViewModel(
            context.read<SosRepository>(),
            context.read<AuthViewModel>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authViewModel = context.watch<AuthViewModel>();

          if (authViewModel.isInitialized) {
            FlutterNativeSplash.remove();
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'SOSecure',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: AppRouter.createRouter(authViewModel),
          );
        },
      ),
    );
  }
}
