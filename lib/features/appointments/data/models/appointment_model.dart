import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/appointment.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    super.id,
    super.clientPhone,
    super.clientName,
    super.serviceType,
    required super.barberId,
    required super.appointmentTime,
    super.status,
    super.sendSms,
    super.smsSent,
    super.smsSentAt,
    super.smsStatus,
    required super.createdAt,
  });

  factory AppointmentModel.fromEntity(Appointment appointment) {
    return AppointmentModel(
      id: appointment.id,
      clientPhone: appointment.clientPhone,
      clientName: appointment.clientName,
      serviceType: appointment.serviceType,
      barberId: appointment.barberId,
      appointmentTime: appointment.appointmentTime,
      status: appointment.status,
      sendSms: appointment.sendSms,
      smsSent: appointment.smsSent,
      smsSentAt: appointment.smsSentAt,
      smsStatus: appointment.smsStatus,
      createdAt: appointment.createdAt,
    );
  }

  factory AppointmentModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data()!;
    return AppointmentModel(
      id: doc.id,
      clientPhone: json[AppointmentFields.clientPhone] as String?,
      clientName: json[AppointmentFields.clientName] as String?,
      serviceType: json[AppointmentFields.serviceType] as String?,
      barberId: json[AppointmentFields.barberId] as String? ?? '',
      appointmentTime: (json[AppointmentFields.appointmentTime] as Timestamp).toDate(),
      status: AppointmentStatusX.fromValue(json[AppointmentFields.status] as String?),
      sendSms: json[AppointmentFields.sendSms] as bool? ?? true,
      smsSent: json[AppointmentFields.smsSent] as bool? ?? false,
      smsSentAt: (json[AppointmentFields.smsSentAt] as Timestamp?)?.toDate(),
      smsStatus: json[AppointmentFields.smsStatus] as String?,
      createdAt: (json[AppointmentFields.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Payload for a brand-new appointment. Server-authoritative fields
  /// (smsSent, timestamps) are always set here rather than trusted from
  /// client state.
  Map<String, dynamic> toCreateJson() {
    return {
      AppointmentFields.clientPhone: clientPhone,
      AppointmentFields.clientName: clientName,
      AppointmentFields.serviceType: serviceType,
      AppointmentFields.barberId: barberId,
      AppointmentFields.appointmentTime: Timestamp.fromDate(appointmentTime),
      AppointmentFields.status: status.value,
      AppointmentFields.sendSms: sendSms,
      AppointmentFields.smsSent: false,
      AppointmentFields.smsSentAt: null,
      AppointmentFields.smsStatus: null,
      AppointmentFields.reminderTaskName: null,
      AppointmentFields.createdAt: FieldValue.serverTimestamp(),
      AppointmentFields.updatedAt: FieldValue.serverTimestamp(),
      AppointmentFields.createdBy: barberId,
    };
  }

  /// Payload for editing an existing appointment (time/name/service/toggle).
  /// Deliberately narrow: never overwrites smsSent/status/reminderTaskName,
  /// those are backend-owned once the appointment exists.
  Map<String, dynamic> toUpdateJson() {
    return {
      AppointmentFields.clientPhone: clientPhone,
      AppointmentFields.clientName: clientName,
      AppointmentFields.serviceType: serviceType,
      AppointmentFields.appointmentTime: Timestamp.fromDate(appointmentTime),
      AppointmentFields.sendSms: sendSms,
      AppointmentFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }
}
