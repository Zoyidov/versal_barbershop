part of 'dashboard_cubit.dart';

enum DashboardStatus { loading, loaded, error }

class DashboardState extends Equatable {
  final DateTime selectedDay;
  final DashboardStatus status;
  final List<Appointment> appointments;
  final String? errorMessage;

  const DashboardState({
    required this.selectedDay,
    this.status = DashboardStatus.loading,
    this.appointments = const [],
    this.errorMessage,
  });

  DashboardState copyWith({
    DateTime? selectedDay,
    DashboardStatus? status,
    List<Appointment>? appointments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      selectedDay: selectedDay ?? this.selectedDay,
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [selectedDay, status, appointments, errorMessage];
}
