import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/managed_user.dart';

class ManagedUserModel extends ManagedUser {
  const ManagedUserModel({
    required super.uid,
    required super.phoneNumber,
    required super.name,
    required super.role,
    required super.active,
    required super.approved,
    required super.smsLimit,
    super.scheduleStartHour,
    super.scheduleEndHour,
  });

  factory ManagedUserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final json = doc.data() ?? const {};
    return ManagedUserModel(
      uid: doc.id,
      phoneNumber: json[UserFields.phoneNumber] as String? ?? '',
      name: json[UserFields.name] as String? ?? '',
      role: json[UserFields.role] as String? ?? UserRoles.barber,
      active: json[UserFields.active] as bool? ?? true,
      approved: json[UserFields.approved] as bool? ?? true,
      smsLimit: (json[UserFields.smsLimit] as num?)?.toInt() ?? 0,
      scheduleStartHour: (json[UserFields.scheduleStartHour] as num?)?.toInt(),
      scheduleEndHour: (json[UserFields.scheduleEndHour] as num?)?.toInt(),
    );
  }
}
