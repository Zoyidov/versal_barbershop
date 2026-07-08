import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../settings/domain/usecases/watch_settings_usecase.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/cancel_appointment_usecase.dart';
import '../../domain/usecases/watch_appointments_for_day_usecase.dart';

part 'dashboard_state.dart';

/// Drives the main dashboard: the horizontal week-day strip plus the
/// real-time hourly schedule of appointments for whichever day is
/// selected. Defaults to today on creation, per spec. Also watches the
/// shop-wide schedule hours (settings/global) so the timetable's start
/// and end times stay in sync with what's configured in Settings.
class DashboardCubit extends Cubit<DashboardState> {
  final WatchAppointmentsForDayUseCase _watchAppointmentsForDayUseCase;
  final CancelAppointmentUseCase _cancelAppointmentUseCase;
  final WatchSettingsUseCase _watchSettingsUseCase;

  StreamSubscription<List<Appointment>>? _subscription;
  StreamSubscription<dynamic>? _settingsSubscription;

  DashboardCubit({
    required WatchAppointmentsForDayUseCase watchAppointmentsForDayUseCase,
    required CancelAppointmentUseCase cancelAppointmentUseCase,
    required WatchSettingsUseCase watchSettingsUseCase,
  })  : _watchAppointmentsForDayUseCase = watchAppointmentsForDayUseCase,
        _cancelAppointmentUseCase = cancelAppointmentUseCase,
        _watchSettingsUseCase = watchSettingsUseCase,
        super(DashboardState(selectedDay: DateTime.now())) {
    _subscribeToDay(state.selectedDay);
    _settingsSubscription = _watchSettingsUseCase().listen((settings) {
      emit(state.copyWith(
        scheduleStartHour: settings.scheduleStartHour,
        scheduleEndHour: settings.scheduleEndHour,
      ));
    });
  }

  void selectDay(DateTime day) {
    if (_isSameDay(day, state.selectedDay)) return;
    emit(state.copyWith(selectedDay: day, status: DashboardStatus.loading, clearError: true));
    _subscribeToDay(day);
  }

  void _subscribeToDay(DateTime day) {
    _subscription?.cancel();
    _subscription = _watchAppointmentsForDayUseCase(day).listen(
      (appointments) {
        emit(state.copyWith(
          status: DashboardStatus.loaded,
          appointments: appointments,
          clearError: true,
        ));
      },
      onError: (error) {
        final message = error is AppException ? error.message : 'Uchrashuvlarni yuklab bo\'lmadi.';
        emit(state.copyWith(status: DashboardStatus.error, errorMessage: message));
      },
    );
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _cancelAppointmentUseCase(appointmentId);
    } on AppException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Future<void> close() {
    _subscription?.cancel();
    _settingsSubscription?.cancel();
    return super.close();
  }
}
