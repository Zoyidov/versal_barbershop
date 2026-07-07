import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/gradient_background.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'root_shell.dart';

class VersalApp extends StatelessWidget {
  const VersalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>()..restoreSession(),
      child: MaterialApp(
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
        home: const _AuthGate(),
      ),
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
            return const RootShell();
          case AuthStatus.unauthenticated:
            return const LoginPage();
          case AuthStatus.unknown:
            return Scaffold(
              body: GradientBackground(
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),
            );
        }
      },
    );
  }
}
