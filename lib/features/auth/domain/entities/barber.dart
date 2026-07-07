import 'package:equatable/equatable.dart';

/// A barber (shop staff account). This is the authenticated user entity —
/// separate from the Firebase Auth UID, which is only a session handle.
class Barber extends Equatable {
  final String uid;
  final String phoneNumber;
  final String name;
  final String role;

  const Barber({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [uid, phoneNumber, name, role];
}
