import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../cubit/auth_cubit.dart';

/// Shown instead of [RootShell] for a signed-in barber whose account hasn't
/// been approved yet (see `_AuthGate` in app.dart). Lets them re-check their
/// status without signing out, since approval happens out-of-band from an
/// admin's user-management screen.
class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  bool _checking = false;

  Future<void> _refresh() async {
    setState(() => _checking = true);
    await context.read<AuthCubit>().refreshCurrentBarber();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.hourglass_top_rounded, color: AppColors.gold, size: 48),
                  const SizedBox(height: 18),
                  Text('Tasdiqlanishi kutilmoqda', style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    'Hisobingiz ro\'yxatdan o\'tdi. Admin tasdiqlagach, band qilish sahifasidan foydalana olasiz.',
                    style: AppTextStyles.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppPrimaryButton(
                          label: 'Holatni tekshirish',
                          loading: _checking,
                          onPressed: _checking ? null : _refresh,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.read<AuthCubit>().logout(),
                          child: Text(
                            'Tizimdan chiqish',
                            style: AppTextStyles.bodyMuted.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
