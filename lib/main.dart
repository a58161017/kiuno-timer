import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiuno_timer/l10n/app_localizations.dart';

import 'application/locale_provider.dart';
import 'presentation/screens/timer_list_page.dart';

/// Entry point for the Just Timer application.
///
/// This app uses Riverpod for state management and Material 3 for theming.
/// It provides both light and dark themes based on the system setting.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const seed = Color(0xFF6750A4);
    final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;

    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Just Timer',
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        final resolved = AppLocalizations.resolveLocale(locale, supportedLocales);
        // 延遲狀態更新，避免在 build 期間寫入 Provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(currentLocaleProvider.notifier).state = resolved;
        });
        return resolved;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        textTheme: baseTextTheme.apply(
          displayColor: const Color(0xFF1B102A),
          bodyColor: const Color(0xFF1B102A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F2FB),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: StadiumBorder(),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1A29),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
      home: const TimerListPage(),
    );
  }
}