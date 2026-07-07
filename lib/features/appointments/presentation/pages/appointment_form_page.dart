import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/appointment_form_cubit.dart';
import '../widgets/cancellation_warning_banner.dart';
import '../widgets/service_type_chips.dart';

class AppointmentFormPage extends StatelessWidget {
  final DateTime defaultDay;
  final Appointment? existing;

  const AppointmentFormPage({super.key, required this.defaultDay, this.existing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentFormCubit>()..init(defaultDay: defaultDay, existing: existing),
      child: const _AppointmentFormView(),
    );
  }
}

class _AppointmentFormView extends StatefulWidget {
  const _AppointmentFormView();

  @override
  State<_AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<_AppointmentFormView> {
  late final TextEditingController _phoneController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppointmentFormCubit>().state;
    _phoneController = TextEditingController(text: state.phoneNumber);
    _nameController = TextEditingController(text: state.clientName);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context) async {
    final cubit = context.read<AppointmentFormCubit>();
    final initial = cubit.state.time ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.gold,
                  surface: AppColors.surface,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) cubit.onTimeSelected(picked);
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Uchrashuvni bekor qilasizmi?', style: AppTextStyles.title),
        content: Text(
          'Uchrashuv bekor qilingan deb belgilanadi. U statistika uchun tarixda saqlanib qoladi.',
          style: AppTextStyles.bodyMuted,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Orqaga')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bekor qilish', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AppointmentFormCubit>().cancelAppointment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: BlocConsumer<AppointmentFormCubit, AppointmentFormState>(
            listenWhen: (p, c) =>
                p.saved != c.saved || p.cancelled != c.cancelled || p.errorMessage != c.errorMessage,
            listener: (context, state) {
              if (state.saved || state.cancelled) {
                Navigator.of(context).pop();
                return;
              }
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            },
            builder: (context, state) {
              final cubit = context.read<AppointmentFormCubit>();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(
                          state.isEditing ? 'Uchrashuvni tahrirlash' : 'Yangi uchrashuv',
                          style: AppTextStyles.headline.copyWith(fontSize: 19),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  controller: _phoneController,
                                  label: 'Telefon raqami *',
                                  hint: '90 123 45 67',
                                  keyboardType: TextInputType.phone,
                                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                                  onChanged: cubit.onPhoneChanged,
                                ),
                                if (state.phoneError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      state.phoneError!,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                                    ),
                                  ),
                                if (state.historyStatus == ClientHistoryLookupStatus.found &&
                                    state.clientHistory != null &&
                                    state.clientHistory!.hasCancellations)
                                  CancellationWarningBanner(history: state.clientHistory!),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _nameController,
                                  label: 'Mijoz ismi (ixtiyoriy)',
                                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                                  onChanged: cubit.onNameChanged,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Vaqt *', style: AppTextStyles.title),
                          const SizedBox(height: 10),
                          GlassCard(
                            onTap: () => _pickTime(context),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.gold),
                                const SizedBox(width: 12),
                                Text(
                                  state.time == null
                                      ? 'Uchrashuv vaqtini tanlang'
                                      : state.time!.format(context),
                                  style: AppTextStyles.body,
                                ),
                                const Spacer(),
                                Text(DateFormatter.fullDate(state.day), style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Xizmat turi (ixtiyoriy)', style: AppTextStyles.title),
                          const SizedBox(height: 10),
                          ServiceTypeChips(
                            selected: state.serviceType,
                            onSelected: cubit.onServiceTypeSelected,
                          ),
                          const SizedBox(height: 18),
                          GlassCard(
                            child: Row(
                              children: [
                                const Icon(Icons.sms_outlined, color: AppColors.gold),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Eslatma SMS yuborish', style: AppTextStyles.title.copyWith(fontSize: 15)),
                                      Text(
                                        'Uchrashuvdan oldin avtomatik yuboriladi',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: state.sendSms,
                                  onChanged: cubit.toggleSendSms,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          AppPrimaryButton(
                            label: state.isEditing ? 'O\'zgarishlarni saqlash' : 'Uchrashuv yaratish',
                            loading: state.submitting,
                            onPressed: state.submitting ? null : cubit.submit,
                          ),
                          if (state.canCancel) ...[
                            const SizedBox(height: 14),
                            AppGhostButton(
                              label: 'Uchrashuvni bekor qilish',
                              icon: Icons.event_busy_outlined,
                              onPressed: state.cancelling ? null : () => _confirmCancel(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
