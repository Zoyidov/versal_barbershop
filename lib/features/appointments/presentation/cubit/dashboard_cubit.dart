import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_exception.dart';
import '../../../auth/domain/entities/barber.dart';
import '../../../auth/domain/usecases/watch_barber_profile_usecase.dart';
import '../../../settings/domain/usecases/watch_settings_usecase.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/cancel_appointment_usecase.dart';
import '../../domain/usecases/watch_appointment_counts_for_range_usecase.dart';
import '../../domain/usecases/watch_appointments_for_day_usecase.dart';

part 'dashboard_state.dart';

/// Drives the main dashboard: the horizontal week-day strip plus the
/// real-time hourly schedule of appointments for whichever day is
/// selected. Defaults to today on creation, per spec. Also watches
/// whichever barber's own working hours apply (falling back to the
/// shop-wide default in settings/global for barbers who haven't set
/// personal hours yet) so the timetable's start/end stay in sync.
class DashboardCubit extends Cubit<DashboardState> {
  // Must match `WeekCalendarStrip`'s `_pastRangeInDays`/`_futureRangeInDays`
  // (lib/core/widgets/week_calendar_strip.dart) - this is the exact window
  // of days the strip can ever scroll to, so counts outside it would never
  // be shown anyway.
  static const int _countsPastRangeInDays = 365;
  static const int _countsFutureRangeInDays = 120;

  final WatchAppointmentsForDayUseCase _watchAppointmentsForDayUseCase;
  final WatchAppointmentCountsForRangeUseCase _watchAppointmentCountsForRangeUseCase;
  final CancelAppointmentUseCase _cancelAppointmentUseCase;
  final WatchSettingsUseCase _watchSettingsUseCase;
  final WatchBarberProfileUseCase _watchBarberProfileUseCase;

  /// Which barber's appointments/hours this cubit shows. The main
  /// dashboard is always fixed to the signed-in user's own uid (every
  /// barber only ever sees their own bookings there); the admin
  /// cross-barber screen instantiates a separate cubit and calls
  /// [setBarberId] from a picker (null there means "every barber", which
  /// has no single personal schedule so it just shows the shop default).
  String? _barberId;

  int? _globalStartHour;
  int? _globalEndHour;
  int? _barberStartHour;
  int? _barberEndHour;

  StreamSubscription<List<Appointment>>? _subscription;
  StreamSubscription<Map<DateTime, int>>? _countsSubscription;
  StreamSubscription<dynamic>? _settingsSubscription;
  StreamSubscription<Barber?>? _barberProfileSubscription;

  DashboardCubit({
    required WatchAppointmentsForDayUseCase watchAppointmentsForDayUseCase,
    required WatchAppointmentCountsForRangeUseCase watchAppointmentCountsForRangeUseCase,
    required CancelAppointmentUseCase cancelAppointmentUseCase,
    required WatchSettingsUseCase watchSettingsUseCase,
    required WatchBarberProfileUseCase watchBarberProfileUseCase,
    String? barberId,
  })  : _watchAppointmentsForDayUseCase = watchAppointmentsForDayUseCase,
        _watchAppointmentCountsForRangeUseCase = watchAppointmentCountsForRangeUseCase,
        _cancelAppointmentUseCase = cancelAppointmentUseCase,
        _watchSettingsUseCase = watchSettingsUseCase,
        _watchBarberProfileUseCase = watchBarberProfileUseCase,
        _barberId = barberId,
        super(DashboardState(selectedDay: DateTime.now())) {
    _subscribeToDay(state.selectedDay);
    _subscribeToDayCounts();
    _settingsSubscription = _watchSettingsUseCase().listen((settings) {
      _globalStartHour = settings.scheduleStartHour;
      _globalEndHour = settings.scheduleEndHour;
      _emitScheduleHours();
    });
    _subscribeToBarberSchedule();
  }

  /// Re-establishes the live counts listener for the whole calendar-strip
  /// window, anchored on today so it doesn't drift as the selected day
  /// changes (unlike [_subscribeToDay], the strip badges cover a fixed
  /// range regardless of which single day is selected).
  void _subscribeToDayCounts() {
    _countsSubscription?.cancel();
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    final start = anchor.subtract(const Duration(days: _countsPastRangeInDays));
    final end = anchor.add(const Duration(days: _countsFutureRangeInDays));
    _countsSubscription = _watchAppointmentCountsForRangeUseCase(start, end, barberId: _barberId).listen(
      (counts) => emit(state.copyWith(dayAppointmentCounts: counts)),
      // Badge counts are a secondary/cosmetic affordance - swallow errors
      // here rather than surfacing them via state.errorMessage, so a
      // transient failure on this stream never covers up (or gets
      // overwritten by) an error from the actual appointments listener.
      onError: (_) {},
    );
  }

  void _subscribeToBarberSchedule() {
    _barberProfileSubscription?.cancel();
    _barberStartHour = null;
    _barberEndHour = null;
    final barberId = _barberId;
    if (barberId == null) {
      _emitScheduleHours();
      return;
    }
    _barberProfileSubscription = _watchBarberProfileUseCase(barberId).listen((barber) {
      _barberStartHour = barber?.scheduleStartHour;
      _barberEndHour = barber?.scheduleEndHour;
      _emitScheduleHours();
    });
  }

  void _emitScheduleHours() {
    final start = _barberStartHour ?? _globalStartHour;
    final end = _barberEndHour ?? _globalEndHour;
    emit(state.copyWith(scheduleStartHour: start, scheduleEndHour: end));
  }

  /// Switches which barber's schedule is shown (admin cross-barber view
  /// only) and re-subscribes for the currently selected day.
  void setBarberId(String? barberId) {
    if (_barberId == barberId) return;
    _barberId = barberId;
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));
    _subscribeToDay(state.selectedDay);
    _subscribeToDayCounts();
    _subscribeToBarberSchedule();
  }

  void selectDay(DateTime day) {
    if (_isSameDay(day, state.selectedDay)) return;
    emit(state.copyWith(selectedDay: day, status: DashboardStatus.loading, clearError: true));
    _subscribeToDay(day);
  }

  /// Re-establishes the appointments listener for the currently selected
  /// day. The data itself is already real-time (Firestore pushes updates
  /// as they happen), so this exists for the pull-to-refresh gesture: it
  /// gives the user a way to force a fresh round-trip to the server (handy
  /// after e.g. a flaky connection) and returns once the next snapshot (or
  /// an error) comes back, which is what [RefreshIndicator] awaits.
  Future<void> refresh() {
    final completer = Completer<void>();
    _subscribeToDay(state.selectedDay, completer: completer);
    return completer.future;
  }

  void _subscribeToDay(DateTime day, {Completer<void>? completer}) {
    _subscription?.cancel();
    _subscription = _watchAppointmentsForDayUseCase(day, barberId: _barberId).listen(
      (appointments) {
        emit(state.copyWith(
          status: DashboardStatus.loaded,
          appointments: appointments,
          clearError: true,
        ));
        if (completer != null && !completer.isCompleted) completer.complete();
      },
      onError: (error) {
        final message = error is AppException ? error.message : 'Uchrashuvlarni yuklab bo\'lmadi.';
        emit(state.copyWith(status: DashboardStatus.error, errorMessage: message));
        if (completer != null && !completer.isCompleted) completer.complete();
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
    _countsSubscription?.cancel();
    _settingsSubscription?.cancel();
    _barberProfileSubscription?.cancel();
    return super.close();
  }
}
