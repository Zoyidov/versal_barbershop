import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/gradient_background.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/pending_approval_page.dart';
import 'features/public_booking/presentation/pages/public_booking_page.dart';
import 'root_shell.dart';

class VersalApp extends StatelessWidget {
  const VersalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The web build is never the barber-facing app - it's the public link
    // clients self-book through (see PublicBookingPage), so it skips the
    // login gate entirely. Every other platform (Android/iOS/desktop) is
    // the authenticated barber/admin app, unchanged below.
    final app = MaterialApp(
      title: 'Versal Barbershop',
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
      // Tapping anywhere outside a focused text field dismisses the
      // keyboard app-wide, without every screen needing its own
      // GestureDetector.
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      home: kIsWeb ? const PublicBookingPage() : const _AuthGate(),
    );

    if (kIsWeb) return app;

    return BlocProvider(
      create: (_) => sl<AuthCubit>()..restoreSession(),
      child: app,
    );
  }
}

/// Chooses between the login screen and the authenticated app shell based
/// on [AuthCubit]'s live auth state, so a session restored on relaunch (or
/// ended via sign-out from Settings) immediately swaps the whole screen.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.authenticated:
            final barber = state.barber;
            if (barber != null && !barber.isAdmin && !barber.approved) {
              return const PendingApprovalPage();
            }
            return const RootShell();
          case AuthStatus.unauthenticated:
            return const LoginPage();
          case AuthStatus.unknown:
            //Versal Barbershop
            return Scaffold(
              key: const ValueKey('unknown_splash'),
              body: GradientBackground(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.gold),
                      const SizedBox(height: 24),
                      Text(
                        'Versal Barbershop',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
