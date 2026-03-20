import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/contacts/contacts_view_model.dart';
import '../ui/home/home_view_model.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SOSecureApp extends StatelessWidget {
  const SOSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ContactsViewModel()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'SOSecure',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
