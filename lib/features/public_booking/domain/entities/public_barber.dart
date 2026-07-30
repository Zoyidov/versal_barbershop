import 'package:equatable/equatable.dart';

/// A barber a walk-in client can pick from on the public booking screen.
/// Deliberately only carries what's safe to show anonymously - never phone,
/// role, or SMS limit (see `getPublicBarbers` in functions/src/publicBooking.ts).
class PublicBarber extends Equatable {
  final String uid;
  final String name;

  const PublicBarber({required this.uid, required this.name});

  @override
  List<Object?> get props => [uid, name];
}
