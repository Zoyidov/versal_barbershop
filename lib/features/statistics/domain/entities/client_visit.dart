import 'package:equatable/equatable.dart';

/// A single past appointment for one client, used to render the dated
/// visit-history list on the client detail screen (which day, what time).
class ClientVisit extends Equatable {
  final DateTime appointmentTime;
  final String status;
  final String? serviceType;
  final DateTime? smsSentAt;
  final String? smsStatus;

  const ClientVisit({
    required this.appointmentTime,
    required this.status,
    this.serviceType,
    this.smsSentAt,
    this.smsStatus,
  });

  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [appointmentTime, status, serviceType, smsSentAt, smsStatus];
}
