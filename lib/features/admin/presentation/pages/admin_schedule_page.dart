import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../../core/widgets/week_calendar_strip.dart';
import '../../../appointments/presentation/cubit/dashboard_cubit.dart';
import '../../../appointments/presentation/widgets/schedule_timetable.dart';
import '../cubit/user_management_cubit.dart';

/// Admin-only, read-only view of any barber's (or every barber's, combined)
/// schedule - separate from the main Dashboard tab, which always stays
/// scoped to the signed-in user's own bookings. Reached from Settings.
class AdminSchedulePage extends StatelessWidget {
  const AdminSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<UserManagementCubit>()),
        BlocProvider(
          create: (_) => sl<DashboardCubit>(instanceName: 'adminSchedule'),
        ),
      ],
      child: const _AdminScheduleView(),
    );
  }
}

class _AdminScheduleView extends StatefulWidget {
  const _AdminScheduleView();

  @override
  State<_AdminScheduleView> createState() => _AdminScheduleViewState();
}

class _AdminScheduleViewState extends State<_AdminScheduleView> {
  String? _selectedBarberId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barberlar jadvali'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: BlocBuilder<UserManagementCubit, UserManagementState>(
          builder: (context, usersState) {
            final barbers = usersState.approvedBarbers;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedBarberId,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(labelText: 'Sartarosh'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Hammasi'),
                      ),
                      ...barbers.map(
                        (b) => DropdownMenuItem<String?>(
                          value: b.uid,
                          child: Text(b.name),
                        ),
                      ),
                    ],
                    onChanged: (uid) {
                      setState(() => _selectedBarberId = uid);
                      context.read<DashboardCubit>().setBarberId(uid);
                    },
                  ),
                ),
                Expanded(
                  child: BlocBuilder<DashboardCubit, DashboardState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                DateFormatter.fullDate(state.selectedDay),
                                style: AppTextStyles.bodyMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          WeekCalendarStrip(
                            selectedDay: state.selectedDay,
                            onDaySelected: (day) =>
                                context.read<DashboardCubit>().selectDay(day),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppColors.gold,
                              onRefresh: () =>
                                  context.read<DashboardCubit>().refresh(),
                              child: _buildBody(state),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(DashboardState state) {
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
      // Read-only: admins view other barbers' schedules here but never
      // create/edit/cancel on their behalf (firestore.rules also requires
      // barberId == request.auth.uid on create, so it couldn't work anyway).
      onTapAppointment: (_) {},
      onQuickCancel: (_) {},
      onAddForHour: (_) {},
    );
  }
}
