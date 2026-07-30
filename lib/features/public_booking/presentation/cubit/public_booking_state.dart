part of 'public_booking_cubit.dart';

enum PublicBookingStatus { loading, loaded, error }

class PublicBookingState extends Equatable {
  final PublicBookingStatus status;
  final List<PublicBarber> barbers;
  final bool barbersLoading;
  final String? selectedBarberId;
  final DateTime selectedDay;
  final DaySlots daySlots;
  final bool isSubmitting;
  final String? errorMessage;

  PublicBookingState({
    this.status = PublicBookingStatus.loading,
    this.barbers = const [],
    this.barbersLoading = true,
    this.selectedBarberId,
    DateTime? selectedDay,
    this.daySlots = DaySlots.empty,
    this.isSubmitting = false,
    this.errorMessage,
  }) : selectedDay = selectedDay ?? DateTime.now();

  PublicBookingState copyWith({
    PublicBookingStatus? status,
    List<PublicBarber>? barbers,
    bool? barbersLoading,
    String? selectedBarberId,
    DateTime? selectedDay,
    DaySlots? daySlots,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return PublicBookingState(
      status: status ?? this.status,
      barbers: barbers ?? this.barbers,
      barbersLoading: barbersLoading ?? this.barbersLoading,
      selectedBarberId: selectedBarberId ?? this.selectedBarberId,
      selectedDay: selectedDay ?? this.selectedDay,
      daySlots: daySlots ?? this.daySlots,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        barbers,
        barbersLoading,
        selectedBarberId,
        selectedDay,
        daySlots,
        isSubmitting,
        errorMessage,
      ];
}
