part of 'dashboard_cubit.dart';

enum DashboardStatus { loading, loaded, error }

class DashboardState extends Equatable {
  final DateTime selectedDay;
  final DashboardStatus status;
  final List<Appointment> appointments;
  final String? errorMessage;
  final int scheduleStartHour;
  final int scheduleEndHour;

  /// Live per-day appointment counts (non-cancelled) across the whole
  /// calendar-strip window, keyed by day (midnight, local time) - drives
  /// `WeekCalendarStrip`'s badges.
  final Map<DateTime, int> dayAppointmentCounts;

  const DashboardState({
    required this.selectedDay,
    this.status = DashboardStatus.loading,
    this.appointments = const [],
    this.errorMessage,
    this.scheduleStartHour = 6,
    this.scheduleEndHour = 20,
    this.dayAppointmentCounts = const {},
  });

  DashboardState copyWith({
    DateTime? selectedDay,
    DashboardStatus? status,
    List<Appointment>? appointments,
    String? errorMessage,
    bool clearError = false,
    int? scheduleStartHour,
    int? scheduleEndHour,
    Map<DateTime, int>? dayAppointmentCounts,
  }) {
    return DashboardState(
      selectedDay: selectedDay ?? this.selectedDay,
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      scheduleStartHour: scheduleStartHour ?? this.scheduleStartHour,
      scheduleEndHour: scheduleEndHour ?? this.scheduleEndHour,
      dayAppointmentCounts: dayAppointmentCounts ?? this.dayAppointmentCounts,
    );
  }

  @override
  List<Object?> get props => [
        selectedDay,
        status,
        appointments,
        errorMessage,
        scheduleStartHour,
        scheduleEndHour,
        dayAppointmentCounts,
      ];
}
