import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../admin/presentation/cubit/pending_approval_cubit.dart';
import '../../../admin/presentation/pages/admin_schedule_page.dart';
import '../../../admin/presentation/pages/user_management_page.dart';
import '../../../auth/domain/entities/barber.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../widgets/app_hour_field.dart';
import '../../widgets/delete_account_dialog.dart';
import '../../widgets/logout_dialog.dart';
import '../cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = sl<SettingsCubit>();
        // The balance is admin-only (see getSmsBalance in
        // functions/src/smsBalance.ts) and, since SettingsCubit no longer
        // auto-fetches it in its constructor, nothing used to trigger this
        // load at all - the card sat on its loading state forever.
        if (context.read<AuthCubit>().state.barber?.isAdmin == true) {
          cubit.loadSmsBalance();
        }
        return cubit;
      },
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  int? _lastSyncedValue;

  final _scheduleFormKey = GlobalKey<FormState>();
  int? _lastSyncedStartHour;
  int? _lastSyncedEndHour;

  int? _startHour;
  int? _endHour;

  final _myScheduleFormKey = GlobalKey<FormState>();
  int? _lastSyncedMyStartHour;
  int? _lastSyncedMyEndHour;
  int? _myStartHour;
  int? _myEndHour;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final minutes = int.parse(_controller.text.trim());
    context.read<SettingsCubit>().updateReminderWindow(minutes);
    FocusScope.of(context).unfocus();
  }

  void _saveScheduleHours(BuildContext context) {
    if (_startHour == null || _endHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boshlanish va tugash soatini tanlang')),
      );
      return;
    }
    if (_startHour! >= _endHour!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Boshlanish vaqti tugash vaqtidan oldin bo\'lishi kerak',
          ),
        ),
      );
      return;
    }
    context.read<SettingsCubit>().updateScheduleHours(_startHour!, _endHour!);
    FocusScope.of(context).unfocus();
  }

  void _saveMyScheduleHours(BuildContext context) {
    if (_myStartHour == null || _myEndHour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boshlanish va tugash soatini tanlang')),
      );
      return;
    }
    if (_myStartHour! >= _myEndHour!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Boshlanish vaqti tugash vaqtidan oldin bo\'lishi kerak',
          ),
        ),
      );
      return;
    }
    context.read<AuthCubit>().updateOwnScheduleHours(
      startHour: _myStartHour!,
      endHour: _myEndHour!,
    );
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ish vaqtingiz yangilandi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<SettingsCubit, SettingsState>(
          listenWhen: (p, c) =>
              p.saved != c.saved || p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.saved) {
              final message =
                  state.savedTarget == SettingsSaveTarget.scheduleHours
                  ? 'Ish jadvali yangilandi'
                  : 'Eslatma vaqti yangilandi';
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },

          builder: (context, state) {
            final authState = context.watch<AuthCubit>().state;
            final barber = authState.barber;
            final isAdmin = barber?.isAdmin == true;

            if (_lastSyncedValue != state.settings.reminderWindowMinutes) {
              _lastSyncedValue = state.settings.reminderWindowMinutes;
              _controller.text = state.settings.reminderWindowMinutes
                  .toString();
            }
            if (_lastSyncedStartHour != state.settings.scheduleStartHour) {
              _lastSyncedStartHour = state.settings.scheduleStartHour;
              _startHour = state.settings.scheduleStartHour;
            }
            if (_lastSyncedEndHour != state.settings.scheduleEndHour) {
              _lastSyncedEndHour = state.settings.scheduleEndHour;
              _endHour = state.settings.scheduleEndHour;
            }
            if (!isAdmin && barber != null) {
              final myStart =
                  barber.scheduleStartHour ?? state.settings.scheduleStartHour;
              final myEnd =
                  barber.scheduleEndHour ?? state.settings.scheduleEndHour;
              if (_lastSyncedMyStartHour != myStart) {
                _lastSyncedMyStartHour = myStart;
                _myStartHour = myStart;
              }
              if (_lastSyncedMyEndHour != myEnd) {
                _lastSyncedMyEndHour = myEnd;
                _myEndHour = myEnd;
              }
            }

            return RefreshIndicator(
              color: AppColors.gold,
              // The reminder-window/schedule cards are already backed by a
              // live Firestore stream, so there's nothing to re-fetch for
              // them - only the SMS balance (a one-shot Cloud Function
              // call, admin-only) actually needs a manual re-fetch here.
              onRefresh: () => isAdmin
                  ? context.read<SettingsCubit>().loadSmsBalance()
                  : Future.value(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    'Sozlamalar',
                    style: AppTextStyles.displayLarge.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 20),
                  if (barber != null) ...[
                    _buildProfileHeader(barber),
                    const SizedBox(height: 20),
                  ],
                  if (isAdmin) ...[
                    _buildSmsBalanceCard(context, state),
                    const SizedBox(height: 24),
                    _sectionLabel(
                      'Do\'kon sozlamalari',
                      Icons.storefront_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildReminderWindowCard(context, state),
                    const SizedBox(height: 16),
                    _buildShopDefaultScheduleCard(context, state),
                    const SizedBox(height: 24),
                    _sectionLabel(
                      'Boshqaruv',
                      Icons.admin_panel_settings_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildAdminLinksCard(context),
                  ] else if (barber != null) ...[
                    _buildMyStatusCard(context, barber),
                  ],
                  const SizedBox(height: 20),
                  AppGhostButton(
                    label: 'Chiqish',
                    icon: Icons.logout,
                    color: AppColors.danger,
                    onPressed: () => showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return const LogoutDialog();
                      },
                    ),
                  ),
                  if (!isAdmin) ...[
                    const SizedBox(height: 30),
                    Center(
                      child: GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (BuildContext context) {
                            return const DeleteAccountDialog();
                          },
                        ),
                        child: Text(
                          'Accountni o\'chirish',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    // AppGhostButton(
                    //   label: 'Hisobni o\'chirish',
                    //   icon: Icons.delete_outline,
                    //   color: AppColors.danger,
                    //   onPressed: () => showDialog(
                    //     context: context,
                    //     barrierDismissible: true,
                    //     builder: (BuildContext context) {
                    //       return const DeleteAccountDialog();
                    //     },
                    //   ),
                    // ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Admin-only: how far ahead of an appointment reminder SMS goes out.
  /// Shop-wide, unlike a barber's own working hours.
  Widget _buildReminderWindowCard(BuildContext context, SettingsState state) {
    return GlassCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SMS eslatma vaqti',
                    style: AppTextStyles.title.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Uchrashuvdan necha daqiqa oldin eslatma SMS yuborilishini belgilaydi. '
              'Bu barcha sartaroshlar uchun amal qiladi va backend tomonidan real vaqtda o\'qiladi.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _controller,
              label: 'Uchrashuvdan necha daqiqa oldin',
              keyboardType: TextInputType.number,
              validator: Validators.reminderMinutes,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text('daq', style: AppTextStyles.bodyMuted),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Saqlash',
              loading: state.saving,
              onPressed: state.saving ? null : () => _save(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Admin-only: the shop-wide fallback schedule, used by any barber (and
  /// the public booking screen) that hasn't set their own working hours.
  Widget _buildShopDefaultScheduleCard(
    BuildContext context,
    SettingsState state,
  ) {
    return GlassCard(
      child: Form(
        key: _scheduleFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_outlined, color: AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Do\'kon standart jadvali',
                    style: AppTextStyles.title.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Shaxsiy ish vaqtini belgilamagan sartaroshlar uchun ishlatiladigan standart jadval.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppHourField(
                    label: 'Boshlanish soati',
                    value: _startHour,
                    onChanged: (val) => setState(() => _startHour = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppHourField(
                    label: 'Tugash soati',
                    value: _endHour,
                    onChanged: (val) => setState(() => _endHour = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Saqlash',
              loading: state.saving,
              onPressed: state.saving
                  ? null
                  : () => _saveScheduleHours(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Small caption-style header with a leading icon, used to visually
  /// group related cards (e.g. "Do'kon sozlamalari", "Boshqaruv") instead
  /// of leaving every card floating with no hierarchy between sections.
  Widget _sectionLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  /// Admin-only navigation into the two management screens, styled as a
  /// single glass menu list (icon chip + title + subtitle + chevron)
  /// rather than two separate outlined buttons.
  Widget _buildAdminLinksCard(BuildContext context) {
    final pendingCount = context.watch<PendingApprovalCubit>().state;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AdminMenuRow(
            icon: Icons.people_alt_outlined,
            title: 'Foydalanuvchilar',
            subtitle: 'Tasdiqlash, SMS limiti, holat',
            badgeCount: pendingCount,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserManagementPage()),
            ),
          ),
          Divider(color: AppColors.surfaceGlassBorder, height: 1, thickness: 1),
          _AdminMenuRow(
            icon: Icons.groups_outlined,
            title: 'Barberlar jadvali',
            subtitle: 'Har bir sartaroshning kunlik bandligi',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminSchedulePage()),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows who's signed in - name, phone, and role - at the top of every
  /// barber's (and admin's) own Settings/profile screen.
  Widget _buildProfileHeader(Barber barber) {
    final initial = barber.name.trim().isNotEmpty
        ? barber.name.trim()[0].toUpperCase()
        : '?';
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.goldGradient),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTextStyles.headline.copyWith(
                fontSize: 22,
                color: AppColors.background,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  barber.name.trim().isNotEmpty ? barber.name : 'Sartarosh',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(barber.phoneNumber, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: barber.isAdmin
                  ? AppColors.gold.withValues(alpha: 0.15)
                  : AppColors.surfaceGlass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: barber.isAdmin
                    ? AppColors.gold
                    : AppColors.surfaceGlassBorder,
              ),
            ),
            child: Text(
              barber.isAdmin ? 'Admin' : 'Sartarosh',
              style: AppTextStyles.caption.copyWith(
                color: barber.isAdmin
                    ? AppColors.gold
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barber-only card (never shown to admin): their own remaining SMS
  /// credit - which also gates whether they can take on new clients - and
  /// their own working hours, both private to them.
  Widget _buildMyStatusCard(BuildContext context, Barber barber) {
    final outOfCredit = !barber.canAddClients;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sms_outlined, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SMS limitim',
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                ),
              ),
              Text(
                '${barber.smsLimit}',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 22,
                  color: outOfCredit ? AppColors.danger : AppColors.gold,
                ),
              ),
            ],
          ),
          if (outOfCredit) ...[
            const SizedBox(height: 8),
            Text(
              'Limitingiz tugadi - yangi mijoz qo\'sha olmaysiz. Admin bilan bog\'laning.',
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 14),
          Divider(
            color: AppColors.textMuted.withOpacity(0.3),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 14),
          Form(
            key: _myScheduleFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined, color: AppColors.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mening ish vaqtim',
                        style: AppTextStyles.title.copyWith(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Faqat sizning jadvalingizga tegishli. Belgilanmasa, do\'kon standart jadvali ishlatiladi.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppHourField(
                        label: 'Boshlanish soati',
                        value: _myStartHour,
                        onChanged: (val) => setState(() => _myStartHour = val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppHourField(
                        label: 'Tugash soati',
                        value: _myEndHour,
                        onChanged: (val) => setState(() => _myEndHour = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Saqlash',
                  onPressed: () => _saveMyScheduleHours(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsBalanceCard(BuildContext context, SettingsState state) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Balans',
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: state.smsBalanceStatus == SmsBalanceStatus.loading
                    ? null
                    : () => context.read<SettingsCubit>().loadSmsBalance(),
              ),
            ],
          ),
          _buildSmsBalanceBody(state),
        ],
      ),
    );
  }

  Widget _buildSmsBalanceBody(SettingsState state) {
    switch (state.smsBalanceStatus) {
      case SmsBalanceStatus.idle:
      case SmsBalanceStatus.loading:
        return const _SmsBalanceShimmer();
      case SmsBalanceStatus.error:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            state.smsBalanceError ?? 'Balansni yuklab bo\'lmadi.',
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
        );
      case SmsBalanceStatus.loaded:
        final balance = state.smsBalance!;
        final fmt = NumberFormat.decimalPattern('uz');
        final remainingSms = balance.smsPrice > 0
            ? balance.balance ~/ balance.smsPrice
            : 0;
        final lowBalance = remainingSms < 10;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              '${fmt.format(balance.balance)} so\'m',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: 28,
                color: lowBalance ? AppColors.danger : AppColors.gold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '1 SMS narxi: ${fmt.format(balance.smsPrice)} so\'m • taxminan $remainingSms ta SMS',
              style: AppTextStyles.caption,
            ),
            if (lowBalance) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Balans kam qoldi - to\'ldirishni unutmang.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SmsStatColumn(
                    label: 'Bugun',
                    smsCount: balance.todaySms,
                    spent: balance.todaySpent,
                    fmt: fmt,
                  ),
                ),
                Expanded(
                  child: _SmsStatColumn(
                    label: 'Bu oy',
                    smsCount: balance.monthSms,
                    spent: balance.monthSpent,
                    fmt: fmt,
                  ),
                ),
                Expanded(
                  child: _SmsStatColumn(
                    label: 'Jami',
                    smsCount: balance.totalSms,
                    spent: balance.totalSpent,
                    fmt: fmt,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _AdminMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Small count badge shown on the icon chip's corner (e.g. barbers
  /// awaiting approval). 0 or omitted shows no badge.
  final int badgeCount;

  const _AdminMenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: AppColors.gold, size: 20),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.title.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton shaped like the loaded balance body (amount, price line, then
/// three stat columns), shown while `getSmsBalance` is in flight instead
/// of a plain spinner so the card doesn't jump size once real data lands.
class _SmsBalanceShimmer extends StatelessWidget {
  const _SmsBalanceShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShimmerBlock(height: 26, width: 150),
          SizedBox(height: 8),
          ShimmerBlock(height: 11, width: 110),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _StatColumnShimmer()),
              Expanded(child: _StatColumnShimmer()),
              Expanded(child: _StatColumnShimmer()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumnShimmer extends StatelessWidget {
  const _StatColumnShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBlock(height: 10, width: 40),
          SizedBox(height: 6),
          ShimmerBlock(height: 13, width: 32),
          SizedBox(height: 4),
          ShimmerBlock(height: 10, width: 48),
        ],
      ),
    );
  }
}

class _SmsStatColumn extends StatelessWidget {
  final String label;
  final int smsCount;
  final int spent;
  final NumberFormat fmt;

  const _SmsStatColumn({
    required this.label,
    required this.smsCount,
    required this.spent,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text('$smsCount ta', style: AppTextStyles.title.copyWith(fontSize: 14)),
        Text(
          '${fmt.format(spent)} so\'m',
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
