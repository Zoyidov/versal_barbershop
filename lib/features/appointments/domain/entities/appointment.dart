import 'package:equatable/equatable.dart';

enum AppointmentStatus { scheduled, cancelled, completed }

extension AppointmentStatusX on AppointmentStatus {
  String get value => name;

  static AppointmentStatus fromValue(String? value) {
    return AppointmentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AppointmentStatus.scheduled,
    );
  }
}

/// Domain entity for a single booking. `id` is null for an appointment
/// that hasn't been persisted to Firestore yet (i.e. still being created).
class Appointment extends Equatable {
  final String? id;
  final String clientPhone;
  final String? clientName;
  final String? serviceType;
  final String barberId;
  final DateTime appointmentTime;
  final AppointmentStatus status;
  final bool sendSms;
  final bool smsSent;
  final DateTime? smsSentAt;
  final String? smsStatus;
  final DateTime createdAt;

  const Appointment({
    this.id,
    required this.clientPhone,
    this.clientName,
    this.serviceType,
    required this.barberId,
    required this.appointmentTime,
    this.status = AppointmentStatus.scheduled,
    this.sendSms = true,
    this.smsSent = false,
    this.smsSentAt,
    this.smsStatus,
    required this.createdAt,
  });

  bool get isCancelled => status == AppointmentStatus.cancelled;

  Appointment copyWith({
    String? id,
    String? clientPhone,
    String? clientName,
    String? serviceType,
    String? barberId,
    DateTime? appointmentTime,
    AppointmentStatus? status,
    bool? sendSms,
    bool? smsSent,
    DateTime? smsSentAt,
    String? smsStatus,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientPhone: clientPhone ?? this.clientPhone,
      clientName: clientName ?? this.clientName,
      serviceType: serviceType ?? this.serviceType,
      barberId: barberId ?? this.barberId,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      sendSms: sendSms ?? this.sendSms,
      smsSent: smsSent ?? this.smsSent,
      smsSentAt: smsSentAt ?? this.smsSentAt,
      smsStatus: smsStatus ?? this.smsStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientPhone,
        clientName,
        serviceType,
        barberId,
        appointmentTime,
        status,
        sendSms,
        smsSent,
        smsSentAt,
        smsStatus,
        createdAt,
      ];
}
