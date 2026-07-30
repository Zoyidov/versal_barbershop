import 'package:equatable/equatable.dart';

/// A barber (shop staff account). This is the authenticated user entity —
/// separate from the Firebase Auth UID, which is only a session handle.
class Barber extends Equatable {
  final String uid;
  final String phoneNumber;
  final String name;
  final String role;

  /// Set by an admin via the approval screen. New self-registrations start
  /// `false` and are routed to a "pending approval" screen until then.
  /// Defaults `true` so accounts created before this field existed (the
  /// original login-only accounts) are grandfathered in as already approved.
  final bool approved;

  /// Remaining SMS credits; decremented server-side on each successful
  /// reminder send. Not enforced when [role] is `'admin'`. Also gates new
  /// bookings: a barber (never an admin) with `smsLimit <= 0` can't be
  /// booked into, client-side or via the public booking link.
  final int smsLimit;

  /// This barber's own working hours. Null until they (or an admin) set
  /// them, in which case the dashboard/public booking fall back to the
  /// shop-wide default in `settings/global`.
  final int? scheduleStartHour;
  final int? scheduleEndHour;

  const Barber({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.role,
    this.approved = true,
    this.smsLimit = 0,
    this.scheduleStartHour,
    this.scheduleEndHour,
  });

  bool get isAdmin => role == 'admin';

  /// Barbers with no SMS credit left can't take on new clients until an
  /// admin tops them up; admins are never metered.
  bool get canAddClients => isAdmin || smsLimit > 0;

  @override
  List<Object?> get props =>
      [uid, phoneNumber, name, role, approved, smsLimit, scheduleStartHour, scheduleEndHour];
}
