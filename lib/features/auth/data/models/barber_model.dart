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
    super.approved,
    super.smsLimit,
    super.scheduleStartHour,
    super.scheduleEndHour,
  });

  factory BarberModel.fromFirestore(String uid, Map<String, dynamic> json) {
    return BarberModel(
      uid: uid,
      phoneNumber: json[UserFields.phoneNumber] as String? ?? '',
      name: json[UserFields.name] as String? ?? '',
      role: json[UserFields.role] as String? ?? 'barber',
      // Absent on accounts created before this field existed - those are
      // grandfathered in as already approved rather than locked out.
      approved: json[UserFields.approved] as bool? ?? true,
      smsLimit: (json[UserFields.smsLimit] as num?)?.toInt() ?? 0,
      scheduleStartHour: (json[UserFields.scheduleStartHour] as num?)?.toInt(),
      scheduleEndHour: (json[UserFields.scheduleEndHour] as num?)?.toInt(),
    );
  }

  factory BarberModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BarberModel.fromFirestore(doc.id, doc.data() ?? const {});
  }

  Barber toEntity() => Barber(
        uid: uid,
        phoneNumber: phoneNumber,
        name: name,
        role: role,
        approved: approved,
        smsLimit: smsLimit,
        scheduleStartHour: scheduleStartHour,
        scheduleEndHour: scheduleEndHour,
      );
}
