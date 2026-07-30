import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/week_calendar_strip.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../public_booking/presentation/pages/public_booking_page.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/schedule_timetable.dart';
import 'appointment_form_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardCubit>(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  Future<void> _confirmCancel(BuildContext context, Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Uchrashuvni bekor qilasizmi?', style: AppTextStyles.title),
        content: Text(
          '${appointment.clientName ?? appointment.clientPhone} uchun uchrashuv bekor qilingan deb belgilanadi.',
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
      context.read<DashboardCubit>().cancelAppointment(appointment.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<DashboardCubit, DashboardState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage && c.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          },
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bosh sahifa', style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(DateFormatter.fullDate(state.selectedDay), style: AppTextStyles.bodyMuted),
                  ),
                ),
                const SizedBox(height: 12),
                WeekCalendarStrip(
                  selectedDay: state.selectedDay,
                  onDaySelected: (day) => context.read<DashboardCubit>().selectDay(day),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.gold,
                    onRefresh: () => context.read<DashboardCubit>().refresh(),
                    child: _buildBody(context, state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppColors.gold,
      //   foregroundColor: AppColors.background,
      //   onPressed: () {
      //     final selectedDay = context.read<DashboardCubit>().state.selectedDay;
      //     _openForm(context, selectedDay);
      //   },
      //   child: const Icon(Icons.add),
      // ),


      // floatingActionButton: FloatingActionButton.extended(
      //   backgroundColor: AppColors.gold,
      //   foregroundColor: AppColors.background,
      //   onPressed: () => Navigator.of(context).push(
      //     MaterialPageRoute(builder: (_) => const PublicBookingPage()),
      //   ),
      //   icon: const Icon(Icons.event_available),
      //   label: const Text('Mijoz uchun band qilish'),
      // ),
    );
  }

  /// Editing an existing appointment keeps the full-page flow; adding a new
  /// one from the dashboard (FAB or an hour slot) opens as a bottom sheet
  /// instead, so the barber never leaves the schedule view.
  void _openForm(
    BuildContext context,
    DateTime day, {
    TimeOfDay? time,
    Appointment? existing,
  }) {
    if (existing != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AppointmentFormPage(defaultDay: day, defaultTime: time, existing: existing),
        ),
      );
      return;
    }

    // A barber out of SMS credit can't take on new clients until an admin
    // tops them up (firestore.rules enforces this server-side too - this
    // is just the friendlier front door). Admins are never metered.
    final barber = context.read<AuthCubit>().state.barber;
    if (barber != null && !barber.canAddClients) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('SMS limiti tugagan', style: AppTextStyles.title),
          content: Text(
            'Yangi mijoz qo\'shish uchun SMS limitingiz yetarli emas. Iltimos, admin bilan bog\'laning.',
            style: AppTextStyles.bodyMuted,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tushunarli')),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.80,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: MediaQuery.removePadding(
            context: sheetContext,
            removeTop: true,
            child: AppointmentFormPage(defaultDay: day, defaultTime: time),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state.status == DashboardStatus.loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: 4,
        itemBuilder: (context, index) => const AppointmentCardShimmer(),
      );
    }

    return ScheduleTimetable(
      appointments: state.appointments,
      startHour: state.scheduleStartHour,
      endHour: state.scheduleEndHour,
      day: state.selectedDay,
      onTapAppointment: (appointment) =>
          _openForm(context, state.selectedDay, existing: appointment),
      onQuickCancel: (appointment) => _confirmCancel(context, appointment),
      onAddForHour: (hour) => _openForm(context, state.selectedDay, time: TimeOfDay(hour: hour, minute: 0)),
    );
  }
}
