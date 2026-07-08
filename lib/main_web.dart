import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/public_booking/presentation/pages/public_booking_page.dart';
import 'firebase_options.dart';

/// Separate web build target (`flutter build web -t lib/main_web.dart`)
/// that serves ONLY the client-facing self-booking screen at the site
/// root - no login, no barber dashboard. `main.dart` (the full auth-gated
/// app used on Android/iOS) is untouched; this exists so the public link
/// shared with clients never bundles or exposes any staff-only screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  await initializeDateFormatting('uz');
  Intl.defaultLocale = 'uz';
  runApp(const PublicBookingWebApp());
}

class PublicBookingWebApp extends StatelessWidget {
  const PublicBookingWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versal Barbershop — Band qilish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: const Locale('uz'),
      supportedLocales: const [Locale('uz'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      home: const PublicBookingPage(),
    );
  }
}
