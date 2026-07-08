part of 'public_booking_cubit.dart';

enum PublicBookingStatus { loading, loaded, error }

class PublicBookingState extends Equatable {
  final PublicBookingStatus status;
  final DateTime selectedDay;
  final DaySlots daySlots;
  final bool isSubmitting;
  final String? errorMessage;

  PublicBookingState({
    this.status = PublicBookingStatus.loading,
    DateTime? selectedDay,
    this.daySlots = DaySlots.empty,
    this.isSubmitting = false,
    this.errorMessage,
  }) : selectedDay = selectedDay ?? DateTime.now();

  PublicBookingState copyWith({
    PublicBookingStatus? status,
    DateTime? selectedDay,
    DaySlots? daySlots,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return PublicBookingState(
      status: status ?? this.status,
      selectedDay: selectedDay ?? this.selectedDay,
      daySlots: daySlots ?? this.daySlots,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, selectedDay, daySlots, isSubmitting, errorMessage];
}
