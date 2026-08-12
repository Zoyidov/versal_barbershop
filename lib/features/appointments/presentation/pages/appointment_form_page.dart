import 'package:flutter/cupertino.dart'
    show
        showCupertinoModalPopup,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoButton,
        CupertinoTheme,
        CupertinoThemeData,
        CupertinoTextThemeData;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/phone_input_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../statistics/domain/entities/client_stat.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/appointment_form_cubit.dart';
import '../widgets/cancellation_warning_banner.dart';
import '../widgets/phone_suggestion_list.dart';
import '../widgets/service_type_chips.dart';

class AppointmentFormPage extends StatelessWidget {
  final DateTime defaultDay;
  final TimeOfDay? defaultTime;
  final Appointment? existing;

  const AppointmentFormPage({super.key, required this.defaultDay, this.defaultTime, this.existing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AppointmentFormCubit>()..init(defaultDay: defaultDay, defaultTime: defaultTime, existing: existing),
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

  // The suggestion dropdown floats in a layer stacked on top of the form
  // (via OverlayPortal, anchored to the phone field with a LayerLink) rather
  // than being laid out inline in the field Column, so it appears above the
  // field without pushing the rest of the form down or resizing the bottom
  // sheet as results come and go.
  final OverlayPortalController _suggestionOverlayController = OverlayPortalController();
  final LayerLink _phoneFieldLink = LayerLink();
  double _phoneFieldWidth = 0;
  List<ClientStat> _overlaySuggestions = const [];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppointmentFormCubit>().state;
    _phoneController = TextEditingController(text: UzPhoneInputFormatter.formatDisplay(state.phoneNumber));
    _nameController = TextEditingController(text: state.clientName);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateSuggestionOverlay(List<ClientStat> suggestions) {
    _overlaySuggestions = suggestions;
    if (suggestions.isEmpty) {
      _suggestionOverlayController.hide();
    } else {
      _suggestionOverlayController.show();
    }
  }

  Widget _buildSuggestionOverlay(BuildContext context) {
    // OverlayPortal (like Overlay/Stack) gives a non-Positioned child tight
    // constraints matching the full overlay size, so the Follower itself
    // ends up screen-sized; Align(bottomCenter) is what actually places our
    // small content flush with the Follower's bottom-center anchor point
    // (which CompositedTransformFollower pins just above the phone field).
    return CompositedTransformFollower(
      link: _phoneFieldLink,
      targetAnchor: Alignment.topCenter,
      followerAnchor: Alignment.bottomCenter,
      offset: const Offset(0, -8),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: _phoneFieldWidth,
            child: PhoneSuggestionList(
              suggestions: _overlaySuggestions,
              onSelected: (client) => _selectSuggestion(context, client),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final cubit = context.read<AppointmentFormCubit>();
    final initial = cubit.state.time ?? TimeOfDay.now();

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      TimeOfDay selectedTime = initial;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoTheme(
            data: const CupertinoThemeData(
              brightness: Brightness.dark,
              primaryColor: AppColors.gold,
              textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 20)),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 320,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(top: BorderSide(color: AppColors.surfaceGlassBorder, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.surfaceGlassBorder, width: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Vaqtni tanlang', style: AppTextStyles.title.copyWith(fontSize: 16)),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                cubit.onTimeSelected(selectedTime);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Tayyor',
                                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: DateTime(2020, 1, 1, initial.hour, initial.minute),
                          use24hFormat: true,
                          onDateTimeChanged: (DateTime newDateTime) {
                            selectedTime = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } else {
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.gold, surface: AppColors.surface),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) cubit.onTimeSelected(picked);
    }
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

  void _selectSuggestion(BuildContext context, ClientStat client) {
    final formatted = UzPhoneInputFormatter.formatDisplay(client.phoneNumber);
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    if (client.lastName != null && client.lastName!.trim().isNotEmpty && _nameController.text.trim().isEmpty) {
      _nameController.text = client.lastName!;
    }
    context.read<AppointmentFormCubit>().selectClientSuggestion(client);
    _suggestionOverlayController.hide();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: BlocConsumer<AppointmentFormCubit, AppointmentFormState>(
            listenWhen: (p, c) =>
                p.saved != c.saved ||
                p.cancelled != c.cancelled ||
                p.errorMessage != c.errorMessage ||
                p.phoneSuggestions != c.phoneSuggestions,
            listener: (context, state) {
              _updateSuggestionOverlay(state.phoneSuggestions);
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
                    padding: const EdgeInsets.fromLTRB(8, 12, 20, 4),
                    child: Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        (state.isEditing)?
                          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_ios)): SizedBox(),
                        Text(
                          state.isEditing ? 'Uchrashuvni tahrirlash' : 'Yangi uchrashuv',
                          style: AppTextStyles.headline.copyWith(fontSize: 19),
                        ),
                        SizedBox(),
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
                                OverlayPortal(
                                  controller: _suggestionOverlayController,
                                  overlayChildBuilder: _buildSuggestionOverlay,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      _phoneFieldWidth = constraints.maxWidth;
                                      return CompositedTransformTarget(
                                        link: _phoneFieldLink,
                                        child: AppTextField(
                                          controller: _phoneController,
                                          label: 'Telefon raqami (ixtiyoriy)',
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [UzPhoneInputFormatter()],
                                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                                          onChanged: cubit.onPhoneChanged,
                                        ),
                                      );
                                    },
                                  ),
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
                                Flexible(
                                  child: Text(
                                    state.time == null ? 'Uchrashuv vaqtini tanlang' : state.time!.format(context),
                                    style: AppTextStyles.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Spacer(),
                                Text(DateFormatter.fullDate(state.day), style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Text('Xizmat turi (ixtiyoriy)', style: AppTextStyles.title),
                          // const SizedBox(height: 10),
                          // ServiceTypeChips(
                          //   selected: state.serviceType,
                          //   onSelected: cubit.onServiceTypeSelected,
                          // ),
                          // const SizedBox(height: 18),
                          Builder(builder: (context) {
                            final hasPhone = state.phoneNumber.trim().isNotEmpty;
                            return GlassCard(
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
                                          hasPhone
                                              ? 'Uchrashuvdan oldin avtomatik yuboriladi'
                                              : 'Telefon raqami kiritilmagan',
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: hasPhone && state.sendSms,
                                    onChanged: hasPhone ? cubit.toggleSendSms : null,
                                  ),
                                ],
                              ),
                            );
                          }),
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
