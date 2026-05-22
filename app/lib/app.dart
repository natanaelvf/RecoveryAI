import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';

/// Root MaterialApp with router, dual themes, and localization.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themePref = ref.watch(themePreferenceProvider);
    final themeMode = themeModeFromPreference(themePref);

    return MaterialApp.router(
      title: 'RecoveryAI',
      debugShowCheckedModeBanner: false,

      // Dual themes — system detection + manual override
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      routerConfig: router,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fi'),
      ],
      locale: const Locale('en'), // Default to English
    );
  }
}
