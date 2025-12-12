import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/router/app_router.dart';
import 'package:marketmove_app/providers/locale_provider.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/theme/app_theme.dart';
import 'package:marketmove_app/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qtetgglxmvivfbdgylbz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0ZXRnZ2x4bXZpdmZiZGd5bGJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MzIzMjQsImV4cCI6MjA3NzEwODMyNH0.kvUeTqnRI6b3d2GjbjXfoxqMvcjKqle29q2rmw6Xyzc',
  );

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: themeService),
      ],
      child: const MarketMoveApp(),
    ),
  );
}

class MarketMoveApp extends StatelessWidget {
  const MarketMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp.router(
      title: 'MarketMove App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.themeMode,
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
