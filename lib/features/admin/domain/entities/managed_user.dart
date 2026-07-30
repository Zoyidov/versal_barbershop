import 'package:equatable/equatable.dart';

/// A barber account as seen by the admin user-management screen. Mirrors
/// `users/{uid}` minus the password fields, which the client never reads.
class ManagedUser extends Equatable {
  final String uid;
  final String phoneNumber;
  final String name;
  final String role;
  final bool active;
  final bool approved;
  final int smsLimit;
  final int? scheduleStartHour;
  final int? scheduleEndHour;

  const ManagedUser({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.role,
    required this.active,
    required this.approved,
    required this.smsLimit,
    this.scheduleStartHour,
    this.scheduleEndHour,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props =>
      [uid, phoneNumber, name, role, active, approved, smsLimit, scheduleStartHour, scheduleEndHour];
}
