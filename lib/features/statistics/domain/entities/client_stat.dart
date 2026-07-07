import 'package:equatable/equatable.dart';

/// Lifetime aggregate for a single client phone number, sourced from the
/// `clients/{phone}` document that the Cloud Functions backend keeps in
/// sync with every appointment create/cancel.
class ClientStat extends Equatable {
  final String phoneNumber;
  final String? lastName;
  final int totalVisits;
  final int totalCancellations;

  const ClientStat({
    required this.phoneNumber,
    this.lastName,
    required this.totalVisits,
    required this.totalCancellations,
  });

  int get totalBookings => totalVisits + totalCancellations;

  @override
  List<Object?> get props => [phoneNumber, lastName, totalVisits, totalCancellations];
}
