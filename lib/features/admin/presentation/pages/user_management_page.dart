import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/managed_user.dart';
import '../cubit/user_management_cubit.dart';
import '../widgets/schedule_hours_dialog.dart';
import '../widgets/sms_limit_dialog.dart';

/// Admin-only screen: approve pending barber registrations (setting their
/// initial SMS credit) and manage already-approved barbers' SMS credit /
/// active status. Reached from Settings, gated on `barber.role == 'admin'`.
class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserManagementCubit>(),
      child: const _UserManagementView(),
    );
  }
}

class _UserManagementView extends StatelessWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foydalanuvchilar'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: BlocConsumer<UserManagementCubit, UserManagementState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == UsersStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              );
            }
            return RefreshIndicator(
              color: AppColors.gold,
              onRefresh: () => context.read<UserManagementCubit>().refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'Tasdiqlashni kutayotganlar',
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (state.pending.isEmpty)
                    Text(
                      'Hozircha kutayotgan ro\'yxatdan o\'tish yo\'q.',
                      style: AppTextStyles.bodyMuted,
                    )
                  else
                    ...state.pending.map(
                      (u) => _PendingUserCard(
                        user: u,
                        busy: state.busyUid == u.uid,
                      ),
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Tasdiqlangan sartaroshlar',
                    style: AppTextStyles.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (state.approvedBarbers.isEmpty)
                    Text(
                      'Hozircha tasdiqlangan sartarosh yo\'q.',
                      style: AppTextStyles.bodyMuted,
                    )
                  else
                    ...state.approvedBarbers.map(
                      (u) => _ApprovedUserCard(
                        user: u,
                        busy: state.busyUid == u.uid,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PendingUserCard extends StatelessWidget {
  final ManagedUser user;
  final bool busy;

  const _PendingUserCard({required this.user, required this.busy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTextStyles.title.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(user.phoneNumber, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            const SizedBox(width: 12),
            busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  )
                : TextButton(
                    onPressed: () async {
                      final smsLimit = await SmsLimitDialog.show(
                        context,
                        title: '${user.name} ni tasdiqlash',
                        confirmLabel: 'Tasdiqlash',
                      );
                      if (smsLimit == null || !context.mounted) return;
                      context.read<UserManagementCubit>().approve(
                        uid: user.uid,
                        smsLimit: smsLimit,
                      );
                    },
                    child: const Text(
                      'Tasdiqlash',
                      style: TextStyle(color: AppColors.gold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ApprovedUserCard extends StatelessWidget {
  final ManagedUser user;
  final bool busy;

  const _ApprovedUserCard({required this.user, required this.busy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTextStyles.title.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(user.phoneNumber, style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 4),
                  Text(
                    'SMS limiti: ${user.smsLimit}',
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    user.scheduleStartHour != null &&
                            user.scheduleEndHour != null
                        ? 'Ish vaqti: ${user.scheduleStartHour}:00 - ${user.scheduleEndHour}:00'
                        : 'Ish vaqti: do\'kon standarti',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              )
            else ...[
              IconButton(
                icon: const Icon(
                  Icons.schedule_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                tooltip: 'Ish vaqti',
                onPressed: () async {
                  final hours = await ScheduleHoursDialog.show(
                    context,
                    title: '${user.name} - ish vaqti',
                    initialStartHour: user.scheduleStartHour,
                    initialEndHour: user.scheduleEndHour,
                  );
                  if (hours == null || !context.mounted) return;
                  context.read<UserManagementCubit>().updateScheduleHours(
                    uid: user.uid,
                    startHour: hours.$1,
                    endHour: hours.$2,
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                tooltip: 'SMS limiti',
                onPressed: () async {
                  final smsLimit = await SmsLimitDialog.show(
                    context,
                    title: '${user.name} - SMS limiti',
                    confirmLabel: 'Saqlash',
                    initialValue: user.smsLimit,
                  );
                  if (smsLimit == null || !context.mounted) return;
                  context.read<UserManagementCubit>().updateSmsLimit(
                    uid: user.uid,
                    smsLimit: smsLimit,
                  );
                },
              ),
              Switch(
                value: user.active,
                activeColor: AppColors.gold,
                onChanged: (value) => context
                    .read<UserManagementCubit>()
                    .setActive(uid: user.uid, active: value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
