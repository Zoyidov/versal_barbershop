import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/barber.dart';

/// Data-layer representation of a barber, aware of Firestore's document
/// shape. Converts to/from the plain [Barber] domain entity at the
/// repository boundary.
class BarberModel extends Barber {
  const BarberModel({
    required super.uid,
    required super.phoneNumber,
    required super.name,
    required super.role,
  });

  factory BarberModel.fromFirestore(String uid, Map<String, dynamic> json) {
    return BarberModel(
      uid: uid,
      phoneNumber: json[UserFields.phoneNumber] as String? ?? '',
      name: json[UserFields.name] as String? ?? '',
      role: json[UserFields.role] as String? ?? 'barber',
    );
  }

  factory BarberModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BarberModel.fromFirestore(doc.id, doc.data() ?? const {});
  }

  Barber toEntity() => Barber(uid: uid, phoneNumber: phoneNumber, name: name, role: role);
}
