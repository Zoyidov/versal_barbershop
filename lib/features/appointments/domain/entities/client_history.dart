import 'package:equatable/equatable.dart';

/// Lightweight lifetime history for a phone number, used to power the
/// "smart alert" banner on the add-appointment form. Backed by the
/// `clients/{phone}` aggregate document, which the Cloud Functions backend
/// keeps up to date whenever an appointment is created or cancelled.
class ClientHistory extends Equatable {
  final String phoneNumber;
  final String? lastName;
  final int totalVisits;
  final int totalCancellations;

  const ClientHistory({
    required this.phoneNumber,
    this.lastName,
    required this.totalVisits,
    required this.totalCancellations,
  });

  bool get hasCancellations => totalCancellations > 0;

  @override
  List<Object?> get props => [phoneNumber, lastName, totalVisits, totalCancellations];
}
