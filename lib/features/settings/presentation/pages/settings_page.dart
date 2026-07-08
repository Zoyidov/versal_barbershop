import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../widgets/app_hour_field.dart';
import '../../widgets/logout_dialog.dart';
import '../cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsCubit>(),
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
        const SnackBar(content: Text('Boshlanish vaqti tugash vaqtidan oldin bo\'lishi kerak')),
      );
      return;
    }
    context.read<SettingsCubit>().updateScheduleHours(_startHour!, _endHour!);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<SettingsCubit, SettingsState>(
          listenWhen: (p, c) => p.saved != c.saved || p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.saved) {
              final message = state.savedTarget == SettingsSaveTarget.scheduleHours
                  ? 'Ish jadvali yangilandi'
                  : 'Eslatma vaqti yangilandi';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
            }
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },

          builder: (context, state) {
            if (_lastSyncedValue != state.settings.reminderWindowMinutes) {
              _lastSyncedValue = state.settings.reminderWindowMinutes;
              _controller.text = state.settings.reminderWindowMinutes.toString();
            }
            if (_lastSyncedStartHour != state.settings.scheduleStartHour) {
              _lastSyncedStartHour = state.settings.scheduleStartHour;
              _startHour = state.settings.scheduleStartHour;
            }
            if (_lastSyncedEndHour != state.settings.scheduleEndHour) {
              _lastSyncedEndHour = state.settings.scheduleEndHour;
              _endHour = state.settings.scheduleEndHour;
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text('Sozlamalar', style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
                const SizedBox(height: 50),
                // Text('Versal BarberShop', textAlign: TextAlign.center, style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
                // const SizedBox(height: 20),
                GlassCard(
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
                              child: Text('SMS eslatma vaqti', style: AppTextStyles.title.copyWith(fontSize: 15)),
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
                            child: Center(widthFactor: 1, child: Text('daq', style: AppTextStyles.bodyMuted)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: AppColors.textMuted.withOpacity(0.3),
                          height: 32,
                          thickness: 1,
                        ),
                        const SizedBox(height: 10),
                        // AppPrimaryButton(
                        //   label: 'Saqlash',
                        //   loading: state.saving,
                        //   onPressed: state.saving ? null : () => _save(context),
                        // ),

                        Form(
                          key: _scheduleFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule_outlined, color: AppColors.gold),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text('Ish jadvali', style: AppTextStyles.title.copyWith(fontSize: 15)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bosh sahifadagi soatlik jadval qaysi vaqt oralig\'ida ko\'rsatilishini belgilaydi.',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppHourField(
                                      label: 'Boshlanish soati',
                                      value: _startHour,
                                      onChanged: (val) {
                                        setState(() => _startHour = val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppHourField(
                                      label: 'Tugash soati',
                                      value: _endHour,
                                      onChanged: (val) {
                                        setState(() => _endHour = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AppPrimaryButton(
                                label: 'Saqlash',
                                loading: state.saving,
                                onPressed: state.saving ? null : () {
                              _saveScheduleHours(context);
                              _save(context);
          }                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // const SizedBox(height: 20),
                // GlassCard(
                //   child: Form(
                //     key: _scheduleFormKey,
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.stretch,
                //       children: [
                //         Row(
                //           children: [
                //             const Icon(Icons.schedule_outlined, color: AppColors.gold),
                //             const SizedBox(width: 10),
                //             Expanded(
                //               child: Text('Ish jadvali', style: AppTextStyles.title.copyWith(fontSize: 15)),
                //             ),
                //           ],
                //         ),
                //         const SizedBox(height: 6),
                //         Text(
                //           'Bosh sahifadagi soatlik jadval qaysi vaqt oralig\'ida ko\'rsatilishini belgilaydi.',
                //           style: AppTextStyles.caption,
                //         ),
                //         const SizedBox(height: 14),
                //         Row(
                //           children: [
                //             Expanded(
                //               child: AppTextField(
                //                 controller: _startHourController,
                //                 label: 'Boshlanish soati',
                //                 keyboardType: TextInputType.number,
                //                 validator: Validators.hourOfDay,
                //               ),
                //             ),
                //             const SizedBox(width: 12),
                //             Expanded(
                //               child: AppTextField(
                //                 controller: _endHourController,
                //                 label: 'Tugash soati',
                //                 keyboardType: TextInputType.number,
                //                 validator: Validators.hourOfDay,
                //               ),
                //             ),
                //           ],
                //         ),
                //         const SizedBox(height: 16),
                //         AppPrimaryButton(
                //           label: 'Saqlash',
                //           loading: state.saving,
                //           onPressed: state.saving ? null : () => _saveScheduleHours(context),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                const SizedBox(height: 24),
                AppGhostButton(
                  label: 'Chiqish',
                  icon: Icons.logout,
                  color: AppColors.textSecondary,
                  onPressed: () => showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return const LogoutDialog();
                    },
                  ),
                  // onPressed: () => context.read<AuthCubit>().logout(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
