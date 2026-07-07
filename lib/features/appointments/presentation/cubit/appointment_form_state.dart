part of 'appointment_form_cubit.dart';

enum AppointmentFormMode { create, edit }

enum ClientHistoryLookupStatus { idle, loading, found, notFound }

class AppointmentFormState extends Equatable {
  final AppointmentFormMode mode;
  final Appointment? existing;

  final String phoneNumber;
  final String? phoneError;
  final String clientName;
  final String? serviceType;
  final DateTime day;
  final TimeOfDay? time;
  final bool sendSms;

  final ClientHistoryLookupStatus historyStatus;
  final ClientHistory? clientHistory;

  final bool submitting;
  final bool cancelling;
  final bool saved;
  final bool cancelled;
  final String? errorMessage;

  const AppointmentFormState({
    this.mode = AppointmentFormMode.create,
    this.existing,
    this.phoneNumber = '',
    this.phoneError,
    this.clientName = '',
    this.serviceType,
    required this.day,
    this.time,
    this.sendSms = true,
    this.historyStatus = ClientHistoryLookupStatus.idle,
    this.clientHistory,
    this.submitting = false,
    this.cancelling = false,
    this.saved = false,
    this.cancelled = false,
    this.errorMessage,
  });

  bool get isEditing => mode == AppointmentFormMode.edit;

  bool get canCancel =>
      isEditing && existing != null && existing!.status == AppointmentStatus.scheduled;

  AppointmentFormState copyWith({
    AppointmentFormMode? mode,
    Appointment? existing,
    String? phoneNumber,
    String? phoneError,
    bool clearPhoneError = false,
    String? clientName,
    String? serviceType,
    bool clearServiceType = false,
    DateTime? day,
    TimeOfDay? time,
    bool? sendSms,
    ClientHistoryLookupStatus? historyStatus,
    ClientHistory? clientHistory,
    bool clearClientHistory = false,
    bool? submitting,
    bool? cancelling,
    bool? saved,
    bool? cancelled,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppointmentFormState(
      mode: mode ?? this.mode,
      existing: existing ?? this.existing,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      clientName: clientName ?? this.clientName,
      serviceType: clearServiceType ? null : (serviceType ?? this.serviceType),
      day: day ?? this.day,
      time: time ?? this.time,
      sendSms: sendSms ?? this.sendSms,
      historyStatus: historyStatus ?? this.historyStatus,
      clientHistory: clearClientHistory ? null : (clientHistory ?? this.clientHistory),
      submitting: submitting ?? this.submitting,
      cancelling: cancelling ?? this.cancelling,
      saved: saved ?? this.saved,
      cancelled: cancelled ?? this.cancelled,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        mode,
        existing,
        phoneNumber,
        phoneError,
        clientName,
        serviceType,
        day,
        time,
        sendSms,
        historyStatus,
        clientHistory,
        submitting,
        cancelling,
        saved,
        cancelled,
        errorMessage,
      ];
}
