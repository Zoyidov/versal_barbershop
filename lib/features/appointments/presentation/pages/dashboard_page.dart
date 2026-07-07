import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../domain/entities/appointment.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/appointment_card.dart';
import '../widgets/week_calendar_strip.dart';
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
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        onPressed: () {
          final selectedDay = context.read<DashboardCubit>().state.selectedDay;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AppointmentFormPage(defaultDay: selectedDay)),
          );
        },
        child: const Icon(Icons.add),
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

    if (state.appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Bu kunga uchrashuvlar yo\'q', style: AppTextStyles.bodyMuted),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: state.appointments.length,
      itemBuilder: (context, index) {
        final appointment = state.appointments[index];
        return AppointmentCard(
          appointment: appointment,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AppointmentFormPage(defaultDay: state.selectedDay, existing: appointment),
              ),
            );
          },
          onQuickCancel: () => _confirmCancel(context, appointment),
        );
      },
    );
  }
}
